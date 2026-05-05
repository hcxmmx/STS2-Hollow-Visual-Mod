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
// 🛡️ 降临协议：接管实体生成阶段 (包含缩放强控)
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature._Ready))]
internal static class NCreature_Ready_Patch
{
    public static readonly System.Collections.Generic.Dictionary<Creature, NCreature> CreatureRegistry = new();

    private static void Postfix(NCreature __instance)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;
        
        CreatureRegistry[entity] = __instance;

        var visuals = __instance.Visuals;
        if (visuals == null) return;

        var player = entity.Player;
        string charId = player?.Character?.Id?.Entry ?? "";

        // 1. 小骑士初始化
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
                    knightNode.Scale = new Vector2(1.0f, 1.0f);

                    var a1 = knightNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                    if (a1 != null)
                    {
                        // 🚨 极其霸道的入场盲盒：从全局池子里随机抓一个！
                        string chosenIntro = HollowGlobals.KnightIntroPool[HollowGlobals.Rng.Next(HollowGlobals.KnightIntroPool.Length)];
                        HollowGlobals.Log($"🎬 随机触发入场动画: {chosenIntro}");
                        a1.Play(chosenIntro); 
                        a1.Queue("Idle"); 
                    }
                }
            }
        }
        // 2. 前辈初始化 (代码强控缩放，防止膨胀爆屏)
        else if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
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
                    seniorNode.Scale = new Vector2(0.72f, 0.72f);
                    
                    var a1 = seniorNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
                    a1?.Play("Roar"); 
                    a1?.Queue("Idle"); 
                }
            }
        }
    }
}

// ==========================================
// ⚔️ 核心指令协议：接管最高司令部 (解决复活失效 & 消除 CS8602)
// ==========================================
[HarmonyPatch(typeof(CreatureCmd), nameof(CreatureCmd.TriggerAnim))]
internal static class CreatureCmd_TriggerAnim_Patch
{
    private static void Prefix(Creature creature, string triggerName)
    {
        if (creature == null) return;
        string trigger = triggerName ?? ""; // 🛡️ 消除 CS8602：确保 trigger 绝不为空

        var player = creature.Player;
        string charId = player?.Character?.Id?.Entry ?? "";
        bool isKnight = player != null && string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase);
        bool isSenior = creature.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty;

        if (!isKnight && !isSenior) return;

        // 🛡️ 消除 CS8602：严格的非空检查
        if (!NCreature_Ready_Patch.CreatureRegistry.TryGetValue(creature, out var nCreature) || !GodotObject.IsInstanceValid(nCreature)) return;

        var visuals = nCreature?.Visuals;
        if (visuals == null) return;

        // ==================================
        // 🎯 目标 A：小骑士
        // ==================================
        if (isKnight)
        {
            if (HollowGlobals.IsKnightDead) return; // 死了就彻底屏蔽信号
            var a1 = visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer");
            if (a1 == null) return;

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
        // ==================================
        // 🎯 目标 B：前辈 (复活逻辑强化版)
        // ==================================
        else if (isSenior)
        {
            var rootNode = visuals.GetNodeOrNull<Node2D>("Senior_Root");
            if (rootNode == null) return; // 简化处理
            var a1 = rootNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
            if (a1 == null) return;

            // 🚨 极其严谨的复活捕捉：只要信号中包含“复活/生成/通灵”等字样，强行重塑肉身！
            string lowerT = trigger.ToLower();
            if (lowerT.Contains("revive") || lowerT.Contains("spawn") || lowerT.Contains("summon") || lowerT.Contains("heal"))
            {
                HollowGlobals.Log($"====== 🌟 捕捉到复活系指令 [{trigger}]，前辈重塑肉身！ ======");
                rootNode.Modulate = new Color(1, 1, 1, 1f);
            }

            // 🚨 极其优雅的查表法：如果 triggerName 就在我们的技能字典里，直接播放！
            if (HollowGlobals.SeniorSkillMap.ContainsKey(trigger))
            {
                rootNode.Modulate = new Color(1, 1, 1, 1f);
                a1.Play(trigger);
                a1.Queue("Idle");
                return; // 攻击动作处理完直接返回，不走下面的 switch
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
}

// ==========================================
// 💀 死亡宣告协议：拦截底层处决 (确保灵体化)
// ==========================================
[HarmonyPatch(typeof(NCreature), "AnimDie")]
internal static class NCreature_AnimDie_Patch
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
        else if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
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
// 📡 物理层动作接管协议：拦截底层动画通讯网 (完美修复复活)
// ==========================================
[HarmonyPatch(typeof(NCreature), nameof(NCreature.SetAnimationTrigger))]
internal static class NCreature_SetAnimationTrigger_Patch
{
    private static void Prefix(NCreature __instance, string trigger)
    {
        if (__instance == null) return;
        var entity = __instance.Entity;
        if (entity == null) return;
        
        // 🚨 检查是不是咱们的前辈
        if (entity.Monster is MegaCrit.Sts2.Core.Models.Monsters.Osty)
        {
            HollowGlobals.Log($"[底层雷达] 前辈接收到物理动作信号: {trigger}");
            
            var visuals = __instance.Visuals;
            if (visuals == null) return;

            var rootNode = visuals.GetNodeOrNull<Node2D>("Senior_Root");
            if (rootNode == null) return;

            var a1 = rootNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");

            // 🚨 极其霸道地在物理层拦截 Revive 信号！
            if (trigger.Equals("Revive", StringComparison.OrdinalIgnoreCase))
            {
                HollowGlobals.Log("====== 🌟 [物理层截获] 前辈极其震撼地重塑肉身！ ======");
                
                // 瞬间将透明度恢复为 100% 实体
                rootNode.Modulate = new Color(1, 1, 1, 1f); 
                
                if (a1 != null)
                {
                    a1.Play("Roar"); // 播放复活怒吼
                    a1.Queue("Idle"); // 切回待机
                }
            }
            // 兜底防御：如果在物理层收到 Hit 信号，也确保他不是半透明的
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

        // 1. 抽签
        var skills = HollowGlobals.SeniorSkillMap.Keys.ToArray();
        string rolledSkill = skills[HollowGlobals.Rng.Next(skills.Length)];
        
        // 2. 直接从字典里拿到准备好的“专属图纸”！
        var vfxScene = HollowGlobals.SeniorSkillMap[rolledSkill];

        // 3. 把本体动作盖戳印在指令上
        __result.WithAttackerAnim(rolledSkill, 0.3f);

        // 4. 极其无脑的精准挂载
        if (vfxScene != null)
        {
            __result.WithHitVfxNode((target) => 
            {
                var vfxNode = vfxScene.Instantiate<Node2D>();
                
                // 终极 GPS 制导
                if (target != null && NCreature_Ready_Patch.CreatureRegistry.TryGetValue(target, out var nTarget) && GodotObject.IsInstanceValid(nTarget))
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
                        // 🚨 如果长官把每个特效里的动画名都统一叫 "Play"：
                        a1.Play("Play"); 
                        
                        // 🚨 如果长官是用动作名作为动画名（比如地刺图纸里就叫 Down_Slam）：
                        // a1.Play(rolledSkill); 
                        
                        HollowGlobals.Log($"====== 🔥 [点火确认] 专属特效阵列部署完毕！ ======");
                    };
                }
                return vfxNode;
            });
        }
    }
}

// ==========================================
// 🏆 胜利结算协议：战斗结束全场谢幕 (终极防爆版)
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Combat.CombatManager), "EndCombatInternal")]
internal static class CombatManager_EndCombatInternal_Patch
{
    private static void Prefix()
    {
        HollowGlobals.Log("🏆 战斗结束，小骑士准备切换胜利姿态...");
        
        // 🚨 加上 .ToList()，防止在遍历字典的时候字典被其他代码修改导致冲突
        foreach (var entry in NCreature_Ready_Patch.CreatureRegistry.ToList())
        {
            var creature = entry.Key;
            var nCreature = entry.Value;

            // 🛡️ 终极防爆盾一：这具肉身还活着吗？是不是上一局的幽灵残留？
            if (!GodotObject.IsInstanceValid(nCreature)) continue;

            if (creature.Player != null && string.Equals(creature.Player.Character?.Id?.Entry, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
            {
                var visuals = nCreature.Visuals;
                
                // 🛡️ 终极防爆盾二：它的视觉中枢还活着吗？
                if (!GodotObject.IsInstanceValid(visuals)) continue;

                var a1 = visuals.GetNodeOrNull<AnimationPlayer>("Knight_Root/AnimationPlayer");
                
                // 🛡️ 终极防爆盾三：动画组件还活着吗？
                if (GodotObject.IsInstanceValid(a1))
                {
                    a1.Play("Idle_Map"); // 极其安稳地切换到胜利结算动画
                }
            }
        }
    }
}