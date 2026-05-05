using System;
using HarmonyLib;
using Godot;
using MegaCrit.Sts2.Core.Entities.Players;
using MegaCrit.sts2.Core.Nodes.TopBar;

namespace Hcxmmx.HollowKnightMod.Scripts;

[HarmonyPatch(typeof(NTopBarPortrait), "Initialize")]
internal static class NTopBarPortrait_Initialize_Patch
{
    private static void Postfix(NTopBarPortrait __instance, Player player)
    {
        if (player?.Character == null) return;

        // 1. 🎯 赛博雷达获取角色 Entry ID
        // 确保你的 HollowGlobals 里有类似 GetCharacterEntry 的反射抓取法，或者直接像房间里那样用
        string charId = player.Character.Id?.Entry ?? "";

        // 2. 🛡️ 身份校验
        if (!string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) 
        {
            return;
        }

        HollowGlobals.Log("====== 🎭 顶部栏雷达：侦测到小骑士降临！执行极其暴力的换脸手术！ ======");

        // 3. 🎨 加载司令部准备好的弹药
        var myIcon = HollowGlobals.TopBarIconTexture;
        var myOutline = HollowGlobals.TopBarOutlineTexture;

        if (myIcon == null || myOutline == null)
        {
            HollowGlobals.Log("💥 顶部栏图标资源缺失，请检查 HollowGlobals 里的路径！");
            return;
        }

        // 4. 🗡️ 启动递归手术刀
        PerformSurgery(__instance, myIcon, myOutline);
    }

    private static void PerformSurgery(Node node, Texture2D icon, Texture2D outline)
    {
        if (node is TextureRect tr)
        {
            string path = tr.Texture?.ResourcePath?.ToLower() ?? "";
            
            // 🚨 极其关键的狙击目标：把原版的 "regent" 改成咱们小骑士的宿主 "necrobinder"
            if (path.Contains("necrobinder"))
            {
                if (path.EndsWith("_outline.png"))
                {
                    tr.Texture = outline;
                }
                else
                {
                    tr.Texture = icon;
                }
            }
        }

        // 极其无情的深度遍历，连根拔起
        foreach (Node child in node.GetChildren())
        {
            PerformSurgery(child, icon, outline);
        }
    }
}