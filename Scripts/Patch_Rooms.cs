using System;
using Godot;
using HarmonyLib;

namespace Hcxmmx.HollowKnightMod.Scripts;

// ==========================================
// 🛍️ 商店雷达：真正的善良商人
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Rooms.NMerchantRoom), nameof(MegaCrit.Sts2.Core.Nodes.Rooms.NMerchantRoom._Ready))]
internal static class NMerchantRoom_Ready_Patch
{
    private static void Postfix(MegaCrit.Sts2.Core.Nodes.Rooms.NMerchantRoom __instance)
    {
        HollowGlobals.Log("\n====== 🛍️ 侦测到进入商店！小骑士开始思考！ ======");
        HollowGlobals.IsInShop = true;

        var players = Traverse.Create(__instance).Field("_players").GetValue<System.Collections.IList>();
        var playerVisuals = Traverse.Create(__instance).Field("_playerVisuals").GetValue<System.Collections.IList>();
        if (players == null || playerVisuals == null || players.Count != playerVisuals.Count) return;

        var characterContainer = __instance.GetNodeOrNull<Control>("%CharacterContainer");
        if (characterContainer == null) return;

        if (HollowGlobals.KnightScenePreloaded == null) return;

        for (int i = 0; i < players.Count; i++)
        {
            // 🚨 极其优雅的幽灵抓取法，彻底无视命名空间壁垒！
            string charId = "";
            var playerTraverse = Traverse.Create(players[i]);
            var character = playerTraverse.Property("Character").GetValue() ?? playerTraverse.Field("Character").GetValue();

            if (character != null)
            {
                var idObj = Traverse.Create(character).Property("Id").GetValue() ?? Traverse.Create(character).Field("Id").GetValue();
                if (idObj != null)
                {
                    charId = Traverse.Create(idObj).Property("Entry").GetValue<string>() ?? Traverse.Create(idObj).Field("Entry").GetValue<string>() ?? "";
                }
            }
            
            if (!string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) continue;

            var targetChild = playerVisuals[i] as Node2D;
            if (targetChild == null) continue;

            targetChild.Hide(); 

            var knightShopNode = HollowGlobals.KnightScenePreloaded.Instantiate<Node2D>();
            knightShopNode.Name = $"KnightShopMecha_{i}";
            characterContainer.AddChild(knightShopNode);

            knightShopNode.Position = targetChild.Position;
            knightShopNode.Scale = new Vector2(1.0f, 1.0f); 

            knightShopNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer")?.Play("Think"); 
        }
    }
}

// 离开商店解锁
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Rooms.NMerchantRoom), "HideScreen")]
internal static class NMerchantRoom_HideScreen_Patch
{
    private static void Prefix() { HollowGlobals.IsInShop = false; }
}

// ==========================================
// 🎭 假商人雷达：极其严密的战备嗅探
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Events.Custom.NFakeMerchant), nameof(MegaCrit.Sts2.Core.Nodes.Events.Custom.NFakeMerchant._Ready))]
internal static class NFakeMerchant_Ready_Patch
{
    private static void Postfix(MegaCrit.Sts2.Core.Nodes.Events.Custom.NFakeMerchant __instance)
    {
        HollowGlobals.Log("\n====== 🎭 侦测到进入假商人房间！小骑士开始思考！ ======");
        HollowGlobals.IsInShop = true; 

        var players = Traverse.Create(__instance).Field("_players").GetValue<System.Collections.IList>();
        var playerVisuals = Traverse.Create(__instance).Field("_playerVisuals").GetValue<System.Collections.IList>();
        if (players == null || playerVisuals == null || players.Count != playerVisuals.Count) return;

        var characterContainer = __instance.GetNodeOrNull<Control>("%CharacterContainer");
        if (characterContainer == null) return;

        // 🚨 终极安全锁：极其严格的战备状态嗅探 (防假商人图穷匕见！)
        var theEvent = Traverse.Create(__instance).Field("_event").GetValue();
        if (theEvent != null)
        {
            bool isFighting = Traverse.Create(theEvent).Property("StartedFight").GetValue<bool>() || 
                              Traverse.Create(theEvent).Field("StartedFight").GetValue<bool>();
            if (isFighting)
            {
                HollowGlobals.Log("🚨 战术拦截！假商人图穷匕见，放弃注入商店机甲，将舞台交还给战斗核心！");
                return; // 极其冷酷地撤退！
            }
        }

        if (HollowGlobals.KnightScenePreloaded == null) return;

        for (int i = 0; i < players.Count; i++)
        {
            // 🚨 极其优雅的幽灵抓取法，彻底无视命名空间壁垒！
            string charId = "";
            var playerTraverse = Traverse.Create(players[i]);
            var character = playerTraverse.Property("Character").GetValue() ?? playerTraverse.Field("Character").GetValue();

            if (character != null)
            {
                var idObj = Traverse.Create(character).Property("Id").GetValue() ?? Traverse.Create(character).Field("Id").GetValue();
                if (idObj != null)
                {
                    charId = Traverse.Create(idObj).Property("Entry").GetValue<string>() ?? Traverse.Create(idObj).Field("Entry").GetValue<string>() ?? "";
                }
            }

            if (!string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) continue;

            var targetChild = playerVisuals[i] as Node2D;
            if (targetChild == null) continue;

            targetChild.Hide();

            var knightShopNode = HollowGlobals.KnightScenePreloaded.Instantiate<Node2D>();
            knightShopNode.Name = $"KnightShopMecha_Fake_{i}";
            characterContainer.AddChild(knightShopNode);

            knightShopNode.Position = targetChild.Position;
            knightShopNode.Scale = new Vector2(1.0f, 1.0f);

            knightShopNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer")?.Play("Think");
        }
    }
}

// 离开假商人房间解锁
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Events.Custom.NFakeMerchant), "HideScreen")]
internal static class NFakeMerchant_HideScreen_Patch
{
    private static void Prefix() { HollowGlobals.IsInShop = false; }
}

// ==========================================
// 🍷 篝火雷达：休息、记录与跨越时空的陪伴
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Rooms.NRestSiteRoom), nameof(MegaCrit.Sts2.Core.Nodes.Rooms.NRestSiteRoom._Ready))]
internal static class NRestSiteRoom_Ready_Patch
{
    // 🚨 极其霸道地缓存当前篝火里的骑士节点，专门用来在离开时执行“洗地”
    public static Node2D? CurrentCampKnightNode = null;

    private static void Postfix(MegaCrit.Sts2.Core.Nodes.Rooms.NRestSiteRoom __instance)
    {
        HollowGlobals.Log("\n====== 🍷 篝火雷达：侦测到进入篝火！小骑士开始写日记！ ======");
        HollowGlobals.IsInShop = true;
        CurrentCampKnightNode = null; // 进门先极其严谨地清空缓存

        var runState = Traverse.Create(__instance).Field("_runState").GetValue();
        if (runState == null) return;

        var players = Traverse.Create(runState).Property("Players").GetValue<System.Collections.IList>() ?? Traverse.Create(runState).Field("Players").GetValue<System.Collections.IList>();
        if (players == null) return;

        if (HollowGlobals.KnightScenePreloaded == null) return;

        for (int i = 0; i < players.Count; i++)
        {
            // 🚨 极其优雅的幽灵抓取法，彻底无视命名空间壁垒！
            string charId = "";
            var playerTraverse = Traverse.Create(players[i]);
            var character = playerTraverse.Property("Character").GetValue() ?? playerTraverse.Field("Character").GetValue();

            if (character != null)
            {
                var idObj = Traverse.Create(character).Property("Id").GetValue() ?? Traverse.Create(character).Field("Id").GetValue();
                if (idObj != null)
                {
                    charId = Traverse.Create(idObj).Property("Entry").GetValue<string>() ?? Traverse.Create(idObj).Field("Entry").GetValue<string>() ?? "";
                }
            }
            if (!string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) continue;

            string containerPath = $"BgContainer/Character_{i + 1}";
            var container = __instance.GetNodeOrNull<Control>(containerPath);
            if (container == null) continue;

            // 启动光学迷彩：把官方坑位的图像透明度降为 0
            for (int j = 0; j < container.GetChildCount(); j++)
            {
                if (container.GetChild(j) is CanvasItem canvasItem)
                {
                    canvasItem.Modulate = new Color(1f, 1f, 1f, 0f);
                }
            }

            var knightCampNode = HollowGlobals.KnightScenePreloaded.Instantiate<Node2D>();
            knightCampNode.Name = $"KnightCampMecha_{i}";
            container.AddChild(knightCampNode);

            knightCampNode.Scale = new Vector2(1.0f, 1.0f);
            knightCampNode.Position = new Vector2(0, 50); 
            
            CurrentCampKnightNode = knightCampNode; // 极其精准地登记肉身缓存

            var a1 = knightCampNode.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
            if (a1 != null)
            {
                // 🎇 极其丝滑的链式接力：看地图 -> 写地图
                a1.AnimationFinished += (animName) =>
                {
                    if (animName == "Sit_Map_Look")
                    {
                        a1.Play("Sit_Map_Write");
                    }
                };
                
                a1.Play("Sit_Map_Look");
            }
        }
    }
}

// 离开篝火解锁 & 清理前辈幻影
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Rooms.NRestSiteRoom), "OnProceedButtonReleased")]
internal static class NRestSiteRoom_Exit_Patch
{
    private static void Prefix() 
    { 
        HollowGlobals.IsInShop = false; 
        
        // 🚨 极其干脆的离场洗地：捕捉离开篝火的瞬间，把前辈的 Sprite 强行关掉
        if (NRestSiteRoom_Ready_Patch.CurrentCampKnightNode != null && GodotObject.IsInstanceValid(NRestSiteRoom_Ready_Patch.CurrentCampKnightNode))
        {
            // ⚠️ 长官注意：请把下面双引号里的 "SeniorSprite_Name_Here" 
            // 替换成你在 Godot 场景树里给前辈那个 Sprite2D 起的真实名字！
            var seniorSprite = NRestSiteRoom_Ready_Patch.CurrentCampKnightNode.GetNodeOrNull<Sprite2D>("Prime"); 
            
            if (seniorSprite != null)
            {
                seniorSprite.Visible = false;
                HollowGlobals.Log("====== 🧹 离开篝火：已极其干脆地将前辈陪伴幻影隐藏！ ======");
            }
        }
    }
}