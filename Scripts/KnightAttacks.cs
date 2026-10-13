using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Commands.Builders;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Nodes.Combat;

namespace Hcxmmx.HollowKnightMod.Scripts;

internal sealed class KnightAttackState { public bool Configured { get; set; } }

internal static class KnightAttacks
{
    public const string TriggerPrefix = "HK_Knight/";
    public static readonly ConditionalWeakTable<AttackCommand, KnightAttackState> Commands = new();
    private static readonly FieldInfo? AnimName = AccessTools.Field(typeof(AttackCommand), "_attackerAnimName");
    private static readonly FieldInfo? AnimDelay = AccessTools.Field(typeof(AttackCommand), "_attackerAnimDelay");
    private static readonly FieldInfo? ShouldAnimate = AccessTools.Field(typeof(AttackCommand), "_shouldPlayAnimation");
    private static readonly FieldInfo? VisualAttacker = AccessTools.Field(typeof(AttackCommand), "_visualAttacker");
    private static readonly Dictionary<string, PackedScene> Scenes = new()
    {
        ["Dark_Descent"] = GD.Load<PackedScene>("res://Hcxmmx_Hollow_Knight_Skin/Scenes/VFX_Knight_Dark_Descent.tscn"),
        ["Cast_Level"] = GD.Load<PackedScene>("res://Hcxmmx_Hollow_Knight_Skin/Scenes/VFX_Knight_Shadow_Soul.tscn"),
        ["Up_Slash"] = GD.Load<PackedScene>("res://Hcxmmx_Hollow_Knight_Skin/Scenes/VFX_Knight_Up_Slash.tscn")
    };

    public static void Configure(AttackCommand command)
    {
        var attacker = command.Attacker;
        if (attacker?.Player?.Character?.Id?.Entry != HollowGlobals.TargetCharacterId) return;
        if (ShouldAnimate?.GetValue(command) is not true) return;
        string? trigger = AnimName?.GetValue(command) as string;
        if (trigger is not ("Attack" or "AttackSingle" or "AttackTriple")) return;
        var visual = VisualAttacker?.GetValue(command) as Creature;
        if (visual != null && !ReferenceEquals(visual, attacker)) return;
        if (!CombatRegistry.CreatureRegistry.TryGetValue(attacker, out var node) || !GodotObject.IsInstanceValid(node)) return;
        var controller = node.Visuals?.GetNodeOrNull<Node>("Knight_Root/IdleController");
        if (controller == null) return;
        var state = Commands.GetValue(command, _ => new KnightAttackState());
        if (state.Configured) return;
        state.Configured = true;
        string action = HollowGlobals.KnightAttackPool[HollowGlobals.Rng.Next(HollowGlobals.KnightAttackPool.Length)];
        float delay = AnimDelay?.GetValue(command) is float originalDelay ? originalDelay : 0.15f;
        if (action is "Dark_Descent" or "Cast_Level") delay = 0.3f;
        else if (action == "Up_Slash") delay = 0.09f;
        command.WithAttackerAnim($"{TriggerPrefix}{trigger}/{action}", delay, visual);
        if (Scenes.TryGetValue(action, out var scene))
            KnightTargetedEffects.Configure(command, controller, action, scene);
    }
}

[HarmonyPatch(typeof(AttackCommand), nameof(AttackCommand.Execute))]
internal static class AttackCommand_Execute_Knight_Patch
{
    private static void Prefix(AttackCommand __instance) => KnightAttacks.Configure(__instance);
}

internal static class KnightTargetedEffects
{
    private static readonly MethodInfo? PossibleTargets = AccessTools.Method(typeof(AttackCommand), "GetPossibleTargets");

    public static void Configure(AttackCommand command, Node controller, string action, PackedScene scene)
    {
        Node2D? cast = null;
        int castRound = -1;
        long roundRevision = -1;
        bool interrupted = false;
        bool CanPlay() => GodotObject.IsInstanceValid(controller) && !controller.IsQueuedForDeletion() &&
                          controller.Call("can_play_attack").AsBool();

        void AddCandidates(Node2D created)
        {
            if (PossibleTargets?.Invoke(command, null) is not IReadOnlyList<Creature> targets) return;
            foreach (var target in targets)
                if (target.IsAlive) Bind(created, controller, target, false);
        }

        Node2D CreateCast()
        {
            var created = scene.Instantiate<Node2D>();
            created.Set("controller", controller);
            created.Set("playback_speed", AnimationPlaybackTiming.CurrentSpeed);
            created.Set("broad_cast", command.IsRandomlyTargeted);
            cast = created;
            castRound = command.Results.Count();
            created.TreeExiting += () =>
            {
                if (ReferenceEquals(cast, created) && created.Get("canceled").AsBool()) interrupted = true;
            };
            return created;
        }

        command.WithAttackerFx(() =>
        {
            if (!CanPlay()) return EmptyNode();
            interrupted = false;
            long revision = controller.Get("action_revision").AsInt64();
            roundRevision = revision + 1;
            var created = CreateCast();
            created.Ready += () =>
            {
                if (!CanPlay()) { created.Call("cancel"); return; }
                long now = controller.Get("action_revision").AsInt64();
                if (now != revision && (now != revision + 1 || controller.Get("current_action").AsString() != action))
                { created.Call("cancel"); return; }
                AddCandidates(created);
                if (now == revision) controller.Call("prepare_attack_cast", created);
                else controller.Call("track_attack_cast", created);
            };
            return created;
        });
        command.WithHitVfxNode(target =>
        {
            if (!CanPlay() || interrupted || controller.Get("action_revision").AsInt64() != roundRevision ||
                controller.Get("current_action").AsString() != action) return EmptyNode();
            if (cast != null && GodotObject.IsInstanceValid(cast) && cast.IsQueuedForDeletion() && cast.Get("canceled").AsBool())
                return EmptyNode();
            int round = command.Results.Count();
            if (cast == null || !GodotObject.IsInstanceValid(cast) || cast.IsQueuedForDeletion() || castRound != round)
            {
                long revision = controller.Get("action_revision").AsInt64();
                var created = CreateCast();
                created.Ready += () =>
                {
                    if (!CanPlay() || controller.Get("action_revision").AsInt64() != revision)
                    { created.Call("cancel"); return; }
                    AddCandidates(created);
                    controller.Call("track_attack_cast", created);
                    Bind(created, controller, target, true);
                };
                return created;
            }
            if (!cast.IsQueuedForDeletion()) Bind(cast, controller, target, true);
            return EmptyNode();
        });
    }

    private static void Bind(Node2D cast, Node controller, Creature target, bool commit)
    {
        if (!cast.IsNodeReady())
        {
            cast.Ready += () => { if (!cast.IsQueuedForDeletion()) Bind(cast, controller, target, commit); };
            return;
        }
        if (cast.IsQueuedForDeletion() || !CombatRegistry.CreatureRegistry.TryGetValue(target, out var node) ||
            !GodotObject.IsInstanceValid(node) || node.IsQueuedForDeletion()) return;
        if (controller.GetParent() is not Node2D knight) return;
        var foot = knight.ToGlobal(controller.Get("world_foot").AsVector2());
        var center = node.GetTopOfHitbox().Lerp(node.GetBottomOfHitbox(), 0.5f);
        var bounds = node.Hitbox.GetGlobalRect();
        var contact = new Vector2(foot.X < center.X ? bounds.Position.X : bounds.End.X, center.Y);
        cast.Call("bind_target_foot", (long)node.GetInstanceId(), node.GetBottomOfHitbox());
        cast.Call("bind_target_contact", (long)node.GetInstanceId(), contact);
        if (commit && !cast.Get("started").AsBool()) controller.Call("track_attack_cast", cast);
        cast.Call(commit ? "commit_target" : "add_target", (long)node.GetInstanceId(), center, foot, Math.Abs(knight.GlobalScale.Y));
    }

    private static Node2D EmptyNode()
    {
        var node = new Node2D();
        node.Ready += node.QueueFree;
        return node;
    }
}
