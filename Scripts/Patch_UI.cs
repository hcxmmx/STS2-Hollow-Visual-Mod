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
        // 1. 查户口：是不是咱们的小骑士（Necrobinder）？
        var entryName = HollowGlobals.GetCharacterEntry(characterModel);
        if (!string.Equals(entryName, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase)) return;

        HollowGlobals.Log("\n====== 🎯 选人雷达：侦测到小骑士，启动极其暴力的视觉劫持！ ======");

        var instanceTraverse = Traverse.Create(__instance);
        var bgContainer = instanceTraverse.Field("_bgContainer").GetValue<Control>();
        var nameLabel = instanceTraverse.Field("_name").GetValue();
        var descLabel = instanceTraverse.Field("_description").GetValue<RichTextLabel>();

        // 2. 极其粗暴地替换背景大图
        if (bgContainer != null)
        {
            // 抹杀官方原版立绘
            foreach (Node child in bgContainer.GetChildren())
            {
                if (child is CanvasItem canvasItem) canvasItem.Hide();
            }

            // 凭空捏造一个相框，极其优雅地省去了进 Godot 建场景的麻烦！
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
                        StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered, // 保持比例居中，绝对不会被拉伸变形
                        MouseFilter = Control.MouseFilterEnum.Ignore
                    };
                    textureRect.SetAnchorsPreset(Control.LayoutPreset.FullRect);
                    bgContainer.AddChild(textureRect);
                }
            }
        }

        // 3. 极其威风地篡改名字
        if (nameLabel != null)
        {
            Traverse.Create(nameLabel).Method("SetTextAutoSize", new object[] { "小骑士" }).GetValue();
        }

        // 4. 极其有沉浸感地篡改背景故事 (长官可自行发挥极其感人的文案！)
        if (descLabel != null)
        {
            descLabel.Text = "来自圣巢的无名容器，与它的前辈并肩作战。\n挥舞骨钉，驾驭虚空与灵魂之力挑战尖塔。";
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

        // 这里极其偷懒地直接复用咱们刚才在顶部栏用过的那个小头像！
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