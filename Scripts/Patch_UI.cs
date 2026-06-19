using System;
using Godot;
using HarmonyLib;

namespace Hcxmmx.HollowKnightMod.Scripts;

// ==========================================
// 🎯 选人界面大厅：替换大立绘与文本介绍
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NCharacterSelectScreen), "SelectCharacter")]
internal static class NCharacterSelectScreen_SelectCharacter_Patch
{
    private static void Postfix(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NCharacterSelectScreen __instance, Node charSelectButton, object characterModel)
    {
        var entryName = HollowGlobals.GetCharacterEntry(characterModel);
        if (!string.Equals(entryName, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) return;

        HollowGlobals.Log("\n====== 🎯 选人雷达：侦测到小骑士，启动极其暴力的视觉劫持！ ======");

        var instanceTraverse = Traverse.Create(__instance);
        var bgContainer = instanceTraverse.Field("_bgContainer").GetValue<Control>();
        var nameLabel = instanceTraverse.Field("_name").GetValue();
        var descLabel = instanceTraverse.Field("_description").GetValue<RichTextLabel>();

        if (bgContainer != null)
        {
            foreach (Node child in bgContainer.GetChildren())
            {
                if (child is CanvasItem canvasItem) canvasItem.Hide();
            }

            if (HollowGlobals.SelectBigTexture != null)
            {
                var existingRect = bgContainer.GetNodeOrNull<TextureRect>("HollowKnight_SelectBg");
                if (existingRect != null)
                {
                    existingRect.Texture = HollowGlobals.SelectBigTexture;
                    existingRect.Show();
                }
                else
                {
                    var textureRect = new TextureRect
                    {
                        Name = "HollowKnight_SelectBg",
                        Texture = HollowGlobals.SelectBigTexture,
                        ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
                        StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered,
                        MouseFilter = Control.MouseFilterEnum.Ignore
                    };
                    textureRect.SetAnchorsPreset(Control.LayoutPreset.FullRect);
                    bgContainer.AddChild(textureRect);
                }
            }
        }

        if (nameLabel != null)
        {
            Traverse.Create(nameLabel).Method("SetTextAutoSize", new object[] { "小骑士" }).GetValue();
        }

        if (descLabel != null)
        {
            descLabel.Text = "来自圣巢的无名容器，与它的前辈并肩作战。\n挥舞骨钉，驾驭虚空与灵魂之力挑战尖塔。";
        }
    }
}

// ==========================================
// 🌐 多人读档界面 (主机端)：替换背景大立绘
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NMultiplayerLoadGameScreen), "InitializeAsHost")]
internal static class NMultiplayerLoadGameScreen_InitializeAsHost_Patch
{
    private static void Postfix(Godot.Node __instance, object run)
    {
        HollowGlobals.Log("\n====== 🌐 多人读档雷达 (Host)：侦测到界面加载！ ======");

        var bgContainer = __instance.GetNodeOrNull<Godot.Control>("%BgContainer") 
                       ?? __instance.GetNodeOrNull<Godot.Control>("BgContainer")
                       ?? __instance.GetNodeOrNull<Godot.Control>("%Bg");
        
        var targetContainer = bgContainer ?? (__instance as Godot.Control);

        string charId = "";
        try {
            var playersList = Traverse.Create(run).Property("Players").GetValue<System.Collections.IList>() 
                           ?? Traverse.Create(run).Field("Players").GetValue<System.Collections.IList>();
            
            if (playersList != null && playersList.Count > 0)
            {
                var hostPlayer = playersList[0]; 
                var modelIdObj = Traverse.Create(hostPlayer).Property("CharacterId").GetValue() 
                              ?? Traverse.Create(hostPlayer).Field("CharacterId").GetValue();
                
                if (modelIdObj != null) charId = modelIdObj.ToString(); 
            }
        } catch (Exception ex) { 
            HollowGlobals.Log($"[Error] Host提取角色ID异常: {ex.Message}");
        }
        HollowGlobals.Log($"Host 最终提取的 ID: '{charId}'");

        if (string.IsNullOrEmpty(charId) || (!charId.Contains("Necrobinder", StringComparison.OrdinalIgnoreCase) && !charId.Contains(HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        if (targetContainer != null && HollowGlobals.SelectBigTexture != null)
        {
            if (bgContainer != null)
            {
                foreach (Godot.Node child in bgContainer.GetChildren())
                {
                    if (child is Godot.CanvasItem canvasItem) canvasItem.Hide();
                }
            }
            else
            {
                // 精准打击：根据日志获取的具体节点名进行隐藏，避免误伤
                var staticBg = targetContainer.GetNodeOrNull<Godot.CanvasItem>("StaticBg");
                if (staticBg != null) staticBg.Hide();

                var animatedBg = targetContainer.GetNodeOrNull<Godot.CanvasItem>("AnimatedBg");
                if (animatedBg != null) animatedBg.Hide();
            }

            var existingRect = targetContainer.GetNodeOrNull<Godot.TextureRect>("HollowKnight_SelectBg");
            if (existingRect != null)
            {
                existingRect.Texture = HollowGlobals.SelectBigTexture;
                existingRect.Show();
            }
            else
            {
                var textureRect = new Godot.TextureRect
                {
                    Name = "HollowKnight_SelectBg",
                    Texture = HollowGlobals.SelectBigTexture,
                    ExpandMode = Godot.TextureRect.ExpandModeEnum.IgnoreSize,
                    StretchMode = Godot.TextureRect.StretchModeEnum.KeepAspectCentered,
                    MouseFilter = Godot.Control.MouseFilterEnum.Ignore
                };
                textureRect.SetAnchorsPreset(Godot.Control.LayoutPreset.FullRect);
                targetContainer.AddChild(textureRect);
                
                if (bgContainer == null) 
                {
                    // 放到图层最底，但因为上面隐藏了原版背景，所以小骑士肯定能露出来！
                    targetContainer.MoveChild(textureRect, 0);
                }
            }
            HollowGlobals.Log($"✅ 成功在 {targetContainer.Name} 上铺设了小骑士的背景图！");
        }
    }
}

// ==========================================
// 🌐 多人读档界面 (客机端)：替换背景大立绘
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NMultiplayerLoadGameScreen), "InitializeAsClient")]
internal static class NMultiplayerLoadGameScreen_InitializeAsClient_Patch
{
    private static void Postfix(Godot.Node __instance, object message)
    {
        HollowGlobals.Log("\n====== 🌐 多人读档雷达 (Client)：侦测到界面加载！ ======");

        var bgContainer = __instance.GetNodeOrNull<Godot.Control>("%BgContainer") 
                       ?? __instance.GetNodeOrNull<Godot.Control>("BgContainer")
                       ?? __instance.GetNodeOrNull<Godot.Control>("%Bg");
        var targetContainer = bgContainer ?? (__instance as Godot.Control);

        string charId = "";
        try {
            var runObj = Traverse.Create(message).Property("Run").GetValue() ?? Traverse.Create(message).Field("Run").GetValue();
            if (runObj != null)
            {
                var playersList = Traverse.Create(runObj).Property("Players").GetValue<System.Collections.IList>() 
                               ?? Traverse.Create(runObj).Field("Players").GetValue<System.Collections.IList>();
                
                if (playersList != null && playersList.Count > 0)
                {
                    var targetPlayer = playersList[0];
                    var modelIdObj = Traverse.Create(targetPlayer).Property("CharacterId").GetValue() 
                                  ?? Traverse.Create(targetPlayer).Field("CharacterId").GetValue();
                    
                    if (modelIdObj != null) charId = modelIdObj.ToString();
                }
            }
        } catch (Exception ex) { 
            HollowGlobals.Log($"[Error] Client提取角色ID异常: {ex.Message}");
        }
        HollowGlobals.Log($"Client 最终提取的 ID: '{charId}'");

        if (string.IsNullOrEmpty(charId) || (!charId.Contains("Necrobinder", StringComparison.OrdinalIgnoreCase) && !charId.Contains(HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        if (targetContainer != null && HollowGlobals.SelectBigTexture != null)
        {
            if (bgContainer != null)
            {
                foreach (Godot.Node child in bgContainer.GetChildren())
                {
                    if (child is Godot.CanvasItem canvasItem) canvasItem.Hide();
                }
            }
            else
            {
                // 精准打击：根据日志获取的具体节点名进行隐藏，避免误伤
                var staticBg = targetContainer.GetNodeOrNull<Godot.CanvasItem>("StaticBg");
                if (staticBg != null) staticBg.Hide();

                var animatedBg = targetContainer.GetNodeOrNull<Godot.CanvasItem>("AnimatedBg");
                if (animatedBg != null) animatedBg.Hide();
            }

            var existingRect = targetContainer.GetNodeOrNull<Godot.TextureRect>("HollowKnight_SelectBg");
            if (existingRect != null)
            {
                existingRect.Texture = HollowGlobals.SelectBigTexture;
                existingRect.Show();
            }
            else
            {
                var textureRect = new Godot.TextureRect
                {
                    Name = "HollowKnight_SelectBg",
                    Texture = HollowGlobals.SelectBigTexture,
                    ExpandMode = Godot.TextureRect.ExpandModeEnum.IgnoreSize,
                    StretchMode = Godot.TextureRect.StretchModeEnum.KeepAspectCentered,
                    MouseFilter = Godot.Control.MouseFilterEnum.Ignore
                };
                textureRect.SetAnchorsPreset(Godot.Control.LayoutPreset.FullRect);
                targetContainer.AddChild(textureRect);
                
                if (bgContainer == null) 
                {
                    targetContainer.MoveChild(textureRect, 0);
                }
            }
            HollowGlobals.Log($"✅ 成功在 {targetContainer.Name} 上铺设了小骑士的背景图！");
        }
    }
}

// ==========================================
// 🔇 选人按钮：替换底部的小头像
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NCharacterSelectButton), "Init")]
internal static class NCharacterSelectButton_Init_Patch_Avatar
{
    private static void Postfix(object __instance, object character)
    {
        var entryName = HollowGlobals.GetCharacterEntry(character);
        if (!string.Equals(entryName, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) return;

        var customAvatar = HollowGlobals.TopBarIconTexture; 
        if (customAvatar == null) return;

        var buttonTraverse = Traverse.Create(__instance);
        var iconNode = buttonTraverse.Field("_icon").GetValue();
        if (iconNode != null)
        {
            Traverse.Create(iconNode).Property("Texture").SetValue(customAvatar);
        }
    }
}