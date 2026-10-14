using System;
using System.Linq;
using System.Reflection;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Nodes.Combat;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Creatures;

namespace Hcxmmx.HollowKnightMod.Scripts;

internal static class CombatRegistry
{
    public static readonly System.Collections.Generic.Dictionary<Creature, NCreature> CreatureRegistry = new();

    public static void CleanupRegistry()
    {
        if (CreatureRegistry.Count == 0) return;

        foreach (var entry in CreatureRegistry.ToList())
        {
            if (!GodotObject.IsInstanceValid(entry.Value))
            {
                CreatureRegistry.Remove(entry.Key);
            }
        }
    }
}

// ==========================================
// 🛡️ 降临协议：接管实体生成阶段 (仅负责注册)
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature._Ready))]
internal static class NCreature_Ready_Register_Patch
{
    private static void Postfix(NCreature __instance)
    {
        if (__instance == null) return;
        CombatRegistry.CleanupRegistry();
        var entity = __instance.Entity;
        if (entity == null) return;

        CombatRegistry.CreatureRegistry[entity] = __instance;
    }
}

// ==========================================
// 🛡️ 降临协议：小骑士挂载
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature._Ready))]
internal static class NCreature_Ready_Knight_Patch
{
    private static void Postfix(NCreature __instance)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;

        var visuals = __instance.Visuals;
        if (visuals == null) return;

        var player = entity.Player;
        string charId = player?.Character?.Id?.Entry ?? "";

        if (player != null && string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
        {
            HollowGlobals.Log("====== 🎯 目标确认！强行挂载小骑士！ ======");
            var originalBody = visuals.GetNodeOrNull<Node2D>("%Visuals");
            if (originalBody != null)
            {
                // Form VFX still follow the native Spine bones. Keep the body
                // updating and only hide its rendering, as in the Flandre skin.
                originalBody.Show();
                var transparent = originalBody.Modulate;
                transparent.A = 0.0f;
                originalBody.Modulate = transparent;
            }

            if (HollowGlobals.KnightScenePreloaded != null)
            {
                var knightNode = HollowGlobals.KnightScenePreloaded.Instantiate<Node2D>();
                if (knightNode != null)
                {
                    knightNode.Name = "Knight_Root";
                    visuals.AddChild(knightNode);
                    KnightLowHealth.Bind(entity, knightNode);

                    // 🚨 强控缩放：放大 1.0 倍！(长官以后想微调就在这里改数字)
                    knightNode.Scale = new Vector2(1.1f, 1.1f);

                    var a1 = knightNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                    if (a1 != null)
                    {
                        // 🚨 极其霸道的入场盲盒：从全局池子里随机抓一个！
                        string chosenIntro = HollowGlobals.KnightIntroPool[HollowGlobals.Rng.Next(HollowGlobals.KnightIntroPool.Length)];
                        HollowGlobals.Log($"🎬 随机触发入场动画: {chosenIntro}");
                        KnightLowHealth.PlayAction(knightNode, chosenIntro);
                    }

                    var syncTimer = new Godot.Timer
                    {
                        Name = "KnightDirectionRadar",
                        WaitTime = 0.05f,
                        Autostart = true
                    };
                    knightNode.AddChild(syncTimer);

                    Node2D? bodyRef = visuals.GetNodeOrNull<Node2D>("%Visuals");
                    Node2D? knightRef = knightNode;

                    syncTimer.Timeout += () =>
                    {
                        if (GodotObject.IsInstanceValid(bodyRef) && GodotObject.IsInstanceValid(knightRef))
                        {
                            float targetSign = Mathf.Sign(bodyRef.Scale.X);
                            float currentSign = Mathf.Sign(knightRef.Scale.X);

                            if (targetSign != currentSign && targetSign != 0)
                            {
                                float absX = Mathf.Abs(knightRef.Scale.X);
                                knightRef.Scale = new Vector2(absX * targetSign, knightRef.Scale.Y);
                            }
                        }
                    };
                }
            }
        }
    }
}

// ==========================================
// ⚔️ 核心指令协议：小骑士动画
// ==========================================
[HarmonyPatch(typeof(CreatureCmd), nameof(CreatureCmd.TriggerAnim))]
internal static class CreatureCmd_TriggerAnim_Knight_Patch
{
    private static void Prefix(Creature creature, ref string triggerName)
    {
        if (creature == null) return;
        string trigger = triggerName ?? ""; // 🛡️ 消除 CS8602：确保 trigger 绝不为空

        var player = creature.Player;
        string charId = player?.Character?.Id?.Entry ?? "";
        bool isKnight = player != null && string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase);

        if (!isKnight) return;

        // Restore the supported native trigger even if the skin node was removed.
        string? selectedAttack = null;
        if (trigger.StartsWith(KnightAttacks.TriggerPrefix, StringComparison.Ordinal))
        {
            var parts = trigger.Split('/');
            if (parts.Length == 3 && HollowGlobals.KnightAttackPool.Contains(parts[2]))
            {
                triggerName = parts[1];
                selectedAttack = parts[2];
            }
        }

        if (!CombatRegistry.CreatureRegistry.TryGetValue(creature, out var nCreature) || !GodotObject.IsInstanceValid(nCreature)) return;

        var visuals = nCreature?.Visuals;
        if (visuals == null) return;

        var a1 = visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer");
        if (a1 == null) return;

        var knightRoot = visuals.GetNodeOrNull<Node2D>("Knight_Root");

        if (selectedAttack != null)
        {
            KnightLowHealth.PlayAction(knightRoot, selectedAttack);
            return;
        }

        switch (trigger)
        {
            case "Attack": case "AttackSingle": case "AttackTriple":
                string atk = HollowGlobals.KnightAttackPool[HollowGlobals.Rng.Next(HollowGlobals.KnightAttackPool.Length)];
                KnightLowHealth.PlayAction(knightRoot, atk); break;
            case "Cast": case "cast": case "Skill":
                string skill = HollowGlobals.KnightSkillPool[HollowGlobals.Rng.Next(HollowGlobals.KnightSkillPool.Length)];
                KnightLowHealth.PlayAction(knightRoot, skill); break;
            case "Hit": case "hurt": KnightLowHealth.PlayAction(knightRoot, "Stun"); break;
            case "Idle": case "idle_loop":
                KnightLowHealth.RequestIdle(knightRoot); break;
            case "Die": case "Death": case "Dead": case "die":
                KnightLowHealth.PlayAction(knightRoot, "Death"); break;
            case "Revive": case "revive":
                KnightLowHealth.Revive(knightRoot); break;
            case "Victory": case "victory":
                KnightLowHealth.RequestVictory(knightRoot); break;
        }
    }
}

// Official revival can bypass CreatureCmd.TriggerAnim entirely.
[HarmonyPatch(typeof(NCreature), nameof(NCreature.StartReviveAnim))]
internal static class NCreature_StartReviveAnim_Knight_Patch
{
    private static void Postfix(NCreature __instance)
    {
        KnightLowHealth.Revive(__instance.Visuals?.GetNodeOrNull<Node2D>("Knight_Root"));
    }
}

// Covers native Revive triggers too. The controller ignores duplicate calls.
[HarmonyPatch(typeof(NCreature), nameof(NCreature.SetAnimationTrigger))]
internal static class NCreature_SetAnimationTrigger_Lifecycle_Knight_Patch
{
    private static void Postfix(NCreature __instance, string trigger)
    {
        if (string.Equals(trigger, "Revive", StringComparison.OrdinalIgnoreCase))
            KnightLowHealth.Revive(__instance.Visuals?.GetNodeOrNull<Node2D>("Knight_Root"));
        else if (string.Equals(trigger, "Victory", StringComparison.OrdinalIgnoreCase))
            KnightLowHealth.RequestVictory(__instance.Visuals?.GetNodeOrNull<Node2D>("Knight_Root"));
    }
}

// ==========================================
// 💀 死亡宣告协议：小骑士
// ==========================================
[HarmonyPatch(typeof(NCreature), "AnimDie")]
internal static class NCreature_AnimDie_Knight_Patch
{
    private static void Prefix(NCreature __instance)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;
        var visuals = __instance.Visuals;
        if (visuals == null) return;

        var player = entity.Player;
        string charId = player?.Character?.Id?.Entry ?? "";

        if (player != null && string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
        {
            KnightLowHealth.PlayAction(visuals.GetNodeOrNull<Node2D>("Knight_Root"), "Death");
        }
    }
}

// ==========================================
// 🏆 胜利结算协议：小骑士
// ==========================================
[HarmonyPatch]
internal static class CombatManager_EndCombatInternal_Knight_Patch
{
    private static MethodBase TargetMethod()
    {
        // New builds end combat through the turn-state overload; older builds
        // expose only the parameterless entry point. Patch exactly one method.
        var methods = typeof(MegaCrit.Sts2.Core.Combat.CombatManager)
            .GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
            .Where(method => method.Name == "EndCombatInternal")
            .ToArray();
        return methods.SingleOrDefault(method => method.GetParameters().Length == 1)
            ?? methods.Single(method => method.GetParameters().Length == 0);
    }

    private static void Prefix()
    {
        HollowGlobals.Log("🏆 战斗结束，小骑士准备切换胜利姿态...");

        CombatRegistry.CleanupRegistry();

        foreach (var entry in CombatRegistry.CreatureRegistry.ToList())
        {
            var creature = entry.Key;
            var nCreature = entry.Value;

            if (!GodotObject.IsInstanceValid(nCreature)) continue;

            if (creature.Player != null && string.Equals(creature.Player.Character?.Id?.Entry, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
            {
                var visuals = nCreature.Visuals;
                if (!GodotObject.IsInstanceValid(visuals)) continue;

                var a1 = visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer");

                if (GodotObject.IsInstanceValid(a1))
                {
                    KnightLowHealth.RequestVictory(visuals.GetNodeOrNull<Node2D>("Knight_Root"));
                }
            }
        }

        CombatRegistry.CreatureRegistry.Clear();
    }
}
