using System;
using System.Runtime.CompilerServices;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Nodes.Combat;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Commands.Builders;

namespace Hcxmmx.HollowKnightMod.Scripts;

internal static class SeniorAnimation
{
    public static Node? Controller(NCreature creature)
    {
        if (!GodotObject.IsInstanceValid(creature) ||
            creature.Entity?.Monster is not MegaCrit.Sts2.Core.Models.Monsters.Osty) return null;
        return creature.Visuals?.GetNodeOrNull<Node>("Senior_Root/AnimationController");
    }

    public static Node? Controller(Creature creature)
    {
        return CombatRegistry.CreatureRegistry.TryGetValue(creature, out var node) ? Controller(node) : null;
    }
}

[HarmonyPatch(typeof(NCreature), nameof(NCreature._Ready))]
internal static class NCreature_Ready_Senior_Patch
{
    private static void Postfix(NCreature __instance)
    {
        if (__instance.Entity?.Monster is not MegaCrit.Sts2.Core.Models.Monsters.Osty) return;
        var visuals = __instance.Visuals;
        if (visuals == null || visuals.HasNode("Senior_Root") || HollowGlobals.SeniorScenePreloaded == null) return;
        CombatRegistry.CreatureRegistry[__instance.Entity] = __instance;
        var originalBody = visuals.GetNodeOrNull<Node2D>("%Visuals");
        originalBody?.Hide();
        var root = HollowGlobals.SeniorScenePreloaded.Instantiate<Node2D>();
        root.Name = "Senior_Root";
        root.Scale = new Vector2(0.9f, 0.9f);
        visuals.AddChild(root);
        var player = root.GetNode<AnimationPlayer>("AnimationPlayer");
        player.Play("Roar");
        player.Queue("Idle");
        var directionTimer = new Godot.Timer
        {
            Name = "SeniorDirectionRadar",
            WaitTime = 0.05f,
            Autostart = true
        };
        root.AddChild(directionTimer);
        directionTimer.Timeout += () =>
        {
            if (!GodotObject.IsInstanceValid(originalBody) || !GodotObject.IsInstanceValid(root)) return;
            float sign = Mathf.Sign(originalBody!.Scale.X);
            if (sign != 0 && sign != Mathf.Sign(root.Scale.X))
                root.Scale = new Vector2(Mathf.Abs(root.Scale.X) * sign, root.Scale.Y);
        };
    }
}

// CreatureCmd.TriggerAnim forwards here; handle each trigger at only this layer.
[HarmonyPatch(typeof(NCreature), nameof(NCreature.SetAnimationTrigger))]
internal static class NCreature_SetAnimationTrigger_Senior_Patch
{
    private static void Prefix(NCreature __instance, string trigger)
    {
        SeniorAnimation.Controller(__instance)?.Call("handle_trigger", trigger);
    }
}

// Fallback for death paths without a Spine trigger. Controller is idempotent.
[HarmonyPatch(typeof(NCreature), "AnimDie")]
internal static class NCreature_AnimDie_Senior_Patch
{
    private static void Prefix(NCreature __instance)
    {
        SeniorAnimation.Controller(__instance)?.Call("play_defeat");
    }
}

// Also covers revive when the original animator has no Revive trigger.
[HarmonyPatch(typeof(NCreature), nameof(NCreature.StartReviveAnim))]
internal static class NCreature_StartReviveAnim_Senior_Patch
{
    private static void Postfix(NCreature __instance)
    {
        SeniorAnimation.Controller(__instance)?.Call("play_revive");
    }
}

internal sealed class SeniorAttackState(Creature creature)
{
    public Creature Creature { get; } = creature;
    public bool Configured { get; set; }
}

internal static class SeniorAttacks
{
    public static readonly ConditionalWeakTable<AttackCommand, SeniorAttackState> Commands = new();
}

[HarmonyPatch(typeof(AttackCommand), nameof(AttackCommand.FromOsty))]
internal static class AttackCommand_FromOsty_Patch
{
    private static void Postfix(AttackCommand __result, Creature osty)
    {
        if (osty?.Monster is not MegaCrit.Sts2.Core.Models.Monsters.Osty) return;
        SeniorAttacks.Commands.Remove(__result);
        SeniorAttacks.Commands.Add(__result, new SeniorAttackState(osty));
    }
}

// Consume combo steps only as execution starts, not while commands are constructed.
[HarmonyPatch(typeof(AttackCommand), nameof(AttackCommand.Execute))]
internal static class AttackCommand_Execute_Senior_Patch
{
    private static void Prefix(AttackCommand __instance)
    {
        if (!SeniorAttacks.Commands.TryGetValue(__instance, out var state) || state.Configured) return;
        var controller = SeniorAnimation.Controller(state.Creature);
        if (controller == null) return;
        string action = controller.Call("next_attack",
            HollowGlobals.Rng.Next(HollowGlobals.SeniorAttackChoices.Length)).AsString();
        if (!HollowGlobals.SeniorSkillMap.TryGetValue(action, out var scene)) return;
        state.Configured = true;
        __instance.WithAttackerAnim(action, 0.3f);
        if (scene == null) return;
        if (action.StartsWith("SwordRain_", StringComparison.Ordinal) || action.StartsWith("Slash_", StringComparison.Ordinal) ||
            action is "Focus_Burst" or "Teleport_Slash" or "Jump_Slam")
        {
            SeniorTargetedEffects.Configure(__instance, controller, action, scene);
            return;
        }
        __instance.WithHitVfxNode(target =>
        {
            var effect = scene.Instantiate<Node2D>();
            effect.Visible = true;
            effect.Modulate = Colors.White;
            // Position only after parenting into the target's VFX container.
            effect.Ready += () =>
            {
                if (CombatRegistry.CreatureRegistry.TryGetValue(target, out var nTarget) &&
                    GodotObject.IsInstanceValid(nTarget) && nTarget.Visuals != null)
                    effect.GlobalPosition = nTarget.Visuals.GlobalPosition;
                effect.GetNodeOrNull<AnimationPlayer>("AnimationPlayer")?.Play("Play");
            };
            return effect;
        });
    }
}

internal static class SeniorTargetedEffects
{
    private static readonly MethodInfo? PossibleTargets = AccessTools.Method(typeof(AttackCommand), "GetPossibleTargets");

    public static void Configure(AttackCommand command, Node controller, string action, PackedScene scene)
    {
        Node2D? cast = null;
        int castRound = -1;
        bool interrupted = false;

        bool CanPlay() => GodotObject.IsInstanceValid(controller) &&
            !controller.IsQueuedForDeletion() && controller.Get("mode").AsString() == "alive";

        void AddCandidates(Node2D created)
        {
            if (PossibleTargets?.Invoke(command, null) is not IReadOnlyList<Creature> targets) return;
            foreach (var target in targets)
                if (target.IsAlive) Bind(created, controller, target, false);
        }

        Node2D CreateCast()
        {
            var created = scene.Instantiate<Node2D>();
            cast = created;
            if (action is "Focus_Burst" or "Teleport_Slash" or "Jump_Slam")
                created.Set("controller", controller);
            // Results is one list per completed hit, including multi-target hits.
            castRound = command.Results.Count();
            SetSpeed(created);
            created.Set("broad_cast", command.IsRandomlyTargeted);
            created.TreeExiting += () =>
            {
                if (ReferenceEquals(cast, created) && created.Get("canceled").AsBool())
                    interrupted = true;
            };
            return created;
        }

        command.WithAttackerFx(() =>
        {
            interrupted = false;
            long revision = controller.Get("action_revision").AsInt64();
            var created = CreateCast();
            created.Ready += () =>
            {
                if (!CanPlay())
                {
                    created.Call("cancel");
                    return;
                }
                long now = controller.Get("action_revision").AsInt64();
                if (now != revision && (now != revision + 1 || controller.Get("current_action").AsString() != action))
                {
                    created.Call("cancel");
                    return;
                }
                // Candidate visuals never pick targets or consume CombatTargets RNG.
                AddCandidates(created);
                if (now == revision) controller.Call("prepare_sword_cast", created);
                else
                {
                    // AddChildSafely may defer parenting until after the trigger.
                    controller.Call("track_sword_cast", created);
                    controller.Call("apply_cast_body_speed", created, action, now);
                }
            };
            return created;
        });
        command.WithHitVfxNode(target =>
        {
            if (!CanPlay() || interrupted) return EmptyNode();
            if (cast != null && GodotObject.IsInstanceValid(cast) && cast.IsQueuedForDeletion() && cast.Get("canceled").AsBool())
                return EmptyNode();
            int round = command.Results.Count();
            if (cast == null || !GodotObject.IsInstanceValid(cast) || cast.IsQueuedForDeletion() || castRound != round)
            {
                // Also handles subsequent hits of OnlyPlayAnimOnce commands.
                long revision = controller.Get("action_revision").AsInt64();
                var created = CreateCast();
                created.Ready += () =>
                {
                    if (!CanPlay() || controller.Get("action_revision").AsInt64() != revision)
                    {
                        created.Call("cancel");
                        return;
                    }
                    AddCandidates(created);
                    controller.Call("track_sword_cast", created);
                    Bind(created, controller, target, true);
                };
                return created;
            }
            // A hit/skill/death that canceled the cast must not bring it back.
            if (GodotObject.IsInstanceValid(cast) && !cast.IsQueuedForDeletion())
                Bind(cast, controller, target, true);
            return EmptyNode();
        });
    }

    private static void SetSpeed(Node2D cast)
    {
        float speed = AnimationPlaybackTiming.CurrentSpeed;
        cast.Set("playback_speed", speed);
        cast.Set("body_speed", speed);
    }

    private static void Bind(Node2D cast, Node controller, Creature target, bool commit)
    {
        if (!cast.IsNodeReady())
        {
            cast.Ready += () =>
            {
                if (!cast.IsQueuedForDeletion()) Bind(cast, controller, target, commit);
            };
            return;
        }
        if (cast.IsQueuedForDeletion()) return;
        if (!CombatRegistry.CreatureRegistry.TryGetValue(target, out var node) ||
            !GodotObject.IsInstanceValid(node) || node.IsQueuedForDeletion()) return;
        if (controller.GetParent() is not Node2D vessel) return;
        var center = node.GetTopOfHitbox().Lerp(node.GetBottomOfHitbox(), 0.5f);
        var foot = vessel.ToGlobal(controller.Get("world_foot").AsVector2());
        float size = Mathf.Max(0.25f, Mathf.Abs(vessel.GlobalScale.Y) / 0.25f);
        if (commit && !cast.Get("started").AsBool()) controller.Call("track_sword_cast", cast);
        if (cast.HasMethod("bind_target_foot"))
            cast.Call("bind_target_foot", (long)node.GetInstanceId(), node.GetBottomOfHitbox());
        cast.Call(commit ? "commit_target" : "add_target", (long)node.GetInstanceId(), center, foot, size);
    }

    private static Node2D EmptyNode()
    {
        var node = new Node2D();
        node.Ready += node.QueueFree;
        return node;
    }
}
