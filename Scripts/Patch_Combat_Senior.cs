using System;
using System.Linq;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Nodes.Combat;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Commands.Builders;

namespace Hcxmmx.HollowKnightMod.Scripts;

// ==========================================
// 🛡️ 降临协议：前辈挂载
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature._Ready))]
internal static class NCreature_Ready_Senior_Patch
{
    private static void Postfix(NCreature __instance)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;

        var visuals = __instance.Visuals;
        if (visuals == null) return;

        if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
        {
            HollowGlobals.Log("====== 🎯 目标确认！强行挂载纯粹容器！ ======");
            visuals.GetNodeOrNull<Node2D>("%Visuals")?.Hide();

            if (HollowGlobals.SeniorScenePreloaded != null)
            {
                var seniorNode = HollowGlobals.SeniorScenePreloaded.Instantiate<Node2D>();
                if (seniorNode != null)
                {
                    seniorNode.Name = "Senior_Root";
                    visuals.AddChild(seniorNode);

                    // 🚨 赛博强控：代码锁定初始缩放！(0.72f 是姐姐计算的黄金比例，长官可微调)
                    seniorNode.Scale = new Vector2(0.9f, 0.9f);

                    var a1 = seniorNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                    a1?.Play("Roar");
                    a1?.Queue("Idle");

                    var syncTimer = new Godot.Timer
                    {
                        Name = "SeniorDirectionRadar",
                        WaitTime = 0.05f,
                        Autostart = true
                    };
                    seniorNode.AddChild(syncTimer);

                    Node2D? bodyRef = visuals.GetNodeOrNull<Node2D>("%Visuals");
                    Node2D? seniorRef = seniorNode;

                    syncTimer.Timeout += () =>
                    {
                        if (GodotObject.IsInstanceValid(bodyRef) && GodotObject.IsInstanceValid(seniorRef))
                        {
                            float targetSign = Mathf.Sign(bodyRef.Scale.X);
                            float currentSign = Mathf.Sign(seniorRef.Scale.X);

                            if (targetSign != currentSign && targetSign != 0)
                            {
                                float absX = Mathf.Abs(seniorRef.Scale.X);
                                seniorRef.Scale = new Vector2(absX * targetSign, seniorRef.Scale.Y);
                            }
                        }
                    };
                }
            }
        }
    }
}

// ==========================================
// ⚔️ 核心指令协议：前辈动画
// ==========================================
[HarmonyPatch(typeof(CreatureCmd), nameof(CreatureCmd.TriggerAnim))]
internal static class CreatureCmd_TriggerAnim_Senior_Patch
{
    private static void Prefix(Creature creature, string triggerName)
    {
        if (creature == null) return;
        string trigger = triggerName ?? "";

        bool isSenior = creature.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty;
        if (!isSenior) return;

        if (!CombatRegistry.CreatureRegistry.TryGetValue(creature, out var nCreature) || !GodotObject.IsInstanceValid(nCreature)) return;

        var visuals = nCreature?.Visuals;
        if (visuals == null) return;

        var rootNode = visuals.GetNodeOrNull<Node2D>("Senior_Root");
        if (rootNode == null) return;
        var a1 = rootNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
        if (a1 == null) return;

        string lowerT = trigger.ToLower();
        if (lowerT.Contains("revive") || lowerT.Contains("spawn") || lowerT.Contains("summon") || lowerT.Contains("heal"))
        {
            HollowGlobals.Log($"====== 🌟 捕捉到复活系指令 [{trigger}]，前辈重塑肉身！ ======");
            rootNode.Modulate = new Color(1, 1, 1, 1f);
        }

        if (HollowGlobals.SeniorSkillMap.ContainsKey(trigger))
        {
            rootNode.Modulate = new Color(1, 1, 1, 1f);
            a1.Play(trigger);
            a1.Queue("Idle");
            return;
        }

        switch (trigger)
        {
            case "Hit": case "hurt":
                rootNode.Modulate = new Color(1, 1, 1, 1f);
                a1.Play("Counter"); a1.Queue("Idle"); break;
            case "Die": case "Death": case "Dead": case "die":
                rootNode.Modulate = new Color(1, 1, 1, 0.4f);
                a1.Play("Idle"); break;
            case "Idle": case "idle_loop": a1.Play("Idle"); break;
        }
    }
}

// ==========================================
// 💀 死亡宣告协议：前辈
// ==========================================
[HarmonyPatch(typeof(NCreature), "AnimDie")]
internal static class NCreature_AnimDie_Senior_Patch
{
    private static void Prefix(NCreature __instance)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;
        var visuals = __instance.Visuals;
        if (visuals == null) return;

        if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
        {
            HollowGlobals.Log("====== 💀 前辈执行 AnimDie 处决，转化为虚空灵体！ ======");
            var rootNode = visuals.GetNodeOrNull<Node2D>("Senior_Root");
            if (rootNode != null)
            {
                rootNode.Modulate = new Color(1, 1, 1, 0.4f);
                rootNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer")?.Play("Idle");
            }
        }
    }
}

// ==========================================
// 📡 物理层动作接管协议：前辈
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature.SetAnimationTrigger))]
internal static class NCreature_SetAnimationTrigger_Senior_Patch
{
    private static void Prefix(NCreature __instance, string trigger)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;

        if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
        {
            HollowGlobals.Log($"[底层雷达] 前辈接收到物理动作信号: {trigger}");

            var visuals = __instance.Visuals;
            if (visuals == null) return;

            var rootNode = visuals.GetNodeOrNull<Node2D>("Senior_Root");
            if (rootNode == null) return;

            var a1 = rootNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");

            if (trigger.Equals("Revive", StringComparison.OrdinalIgnoreCase))
            {
                HollowGlobals.Log("====== 🌟 [物理层截获] 前辈极其震撼地重塑肉身！ ======");

                rootNode.Modulate = new Color(1, 1, 1, 1f);

                if (a1 != null)
                {
                    a1.Play("Roar");
                    a1.Queue("Idle");
                }
            }
            else if (trigger.Equals("Hit", StringComparison.OrdinalIgnoreCase))
            {
                rootNode.Modulate = new Color(1, 1, 1, 1f);
                if (a1 != null)
                {
                    a1.Play("Counter");
                    a1.Queue("Idle");
                }
            }
        }
    }
}

[HarmonyPatch(typeof(AttackCommand), nameof(AttackCommand.FromOsty))]
internal static class AttackCommand_FromOsty_Patch
{
    private static void Postfix(AttackCommand __result, Creature osty)
    {
        if (osty?.Monster is not MegaCrit.Sts2.Core.Models.Monsters.Osty) return;

        var skills = HollowGlobals.SeniorSkillKeys;
        if (skills.Length == 0) return;
        string rolledSkill = skills[HollowGlobals.Rng.Next(skills.Length)];

        var vfxScene = HollowGlobals.SeniorSkillMap[rolledSkill];

        __result.WithAttackerAnim(rolledSkill, 0.3f);

        if (vfxScene != null)
        {
            __result.WithHitVfxNode((target) =>
            {
                var vfxNode = vfxScene.Instantiate<Node2D>();

                if (target != null && CombatRegistry.CreatureRegistry.TryGetValue(target, out var nTarget) && GodotObject.IsInstanceValid(nTarget))
                {
                    if (nTarget.Visuals != null) vfxNode.GlobalPosition = nTarget.Visuals.GlobalPosition;
                }
                vfxNode.Visible = true;
                vfxNode.Modulate = new Color(1, 1, 1, 1f);

                var a1 = vfxNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                if (a1 != null)
                {
                    vfxNode.Ready += () =>
                    {
                        a1.Play("Play");
                        HollowGlobals.Log("====== 🔥 [点火确认] 专属特效阵列部署完毕！ ======");
                    };
                }
                return vfxNode;
            });
        }
    }
}
