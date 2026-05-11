using System;
using System.Linq;
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
            HollowGlobals.IsKnightDead = false;
            HollowGlobals.Log("====== 🎯 目标确认！强行挂载小骑士！ ======");
            visuals.GetNodeOrNull<Node2D>("%Visuals")?.Hide();

            if (HollowGlobals.KnightScenePreloaded != null)
            {
                var knightNode = HollowGlobals.KnightScenePreloaded.Instantiate<Node2D>();
                if (knightNode != null)
                {
                    knightNode.Name = "Knight_Root";
                    visuals.AddChild(knightNode);

                    // 🚨 强控缩放：放大 1.0 倍！(长官以后想微调就在这里改数字)
                    knightNode.Scale = new Vector2(1.1f, 1.1f);

                    var a1 = knightNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                    if (a1 != null)
                    {
                        // 🚨 极其霸道的入场盲盒：从全局池子里随机抓一个！
                        string chosenIntro = HollowGlobals.KnightIntroPool[HollowGlobals.Rng.Next(HollowGlobals.KnightIntroPool.Length)];
                        HollowGlobals.Log($"🎬 随机触发入场动画: {chosenIntro}");
                        a1.Play(chosenIntro);
                        a1.Queue("Idle");
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
    private static void ClearVfxChildren(Node2D mechaNode)
    {
        foreach (var childName in HollowGlobals.VfxChildPool)
        {
            var vfxChild = HollowGlobals.FindFirstNode<AnimatedSprite2D>(mechaNode, n =>
                string.Equals(n.Name.ToString(), childName, StringComparison.Ordinal));

            vfxChild?.Hide();
        }
    }

    private static void Prefix(Creature creature, string triggerName)
    {
        if (creature == null) return;
        string trigger = triggerName ?? ""; // 🛡️ 消除 CS8602：确保 trigger 绝不为空

        var player = creature.Player;
        string charId = player?.Character?.Id?.Entry ?? "";
        bool isKnight = player != null && string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase);

        if (!isKnight) return;

        if (!CombatRegistry.CreatureRegistry.TryGetValue(creature, out var nCreature) || !GodotObject.IsInstanceValid(nCreature)) return;

        var visuals = nCreature?.Visuals;
        if (visuals == null) return;

        if (HollowGlobals.IsKnightDead) return; // 死了就彻底屏蔽信号
        var a1 = visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer");
        if (a1 == null) return;

        var knightRoot = visuals.GetNodeOrNull<Node2D>("Knight_Root");
        if (knightRoot != null) ClearVfxChildren(knightRoot);

        switch (trigger)
        {
            case "Attack": case "AttackSingle": case "AttackTriple":
                string atk = HollowGlobals.KnightAttackPool[HollowGlobals.Rng.Next(HollowGlobals.KnightAttackPool.Length)];
                a1.Play(atk); a1.Queue("Idle"); break;
            case "Cast": case "cast": case "Skill":
                string skill = HollowGlobals.KnightSkillPool[HollowGlobals.Rng.Next(HollowGlobals.KnightSkillPool.Length)];
                a1.Play(skill); a1.Queue("Idle"); break;
            case "Hit": case "hurt": a1.Play("Stun"); a1.Queue("Idle"); break;
            case "Die": case "Death": case "Dead": case "die":
                HollowGlobals.IsKnightDead = true; a1.Play("Death"); break;
            case "Victory": case "victory":
                a1.Play("Idle_Map"); break;
        }
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
            HollowGlobals.IsKnightDead = true;
            visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer")?.Play("Death");
        }
    }
}

// ==========================================
// 🏆 胜利结算协议：小骑士
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Combat.CombatManager), "EndCombatInternal")]
internal static class CombatManager_EndCombatInternal_Knight_Patch
{
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
                    a1.Play("Idle_Map");
                }
            }
        }

        CombatRegistry.CreatureRegistry.Clear();
    }
}
