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
// 🌐 多人读档界面 (主机端)：替换背景大立绘
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NMultiplayerLoadGameScreen), "InitializeAsHost")] // 注意你的命名空间
internal static class NMultiplayerLoadGameScreen_InitializeAsHost_Patch
{
    private static void Postfix(Godot.Node __instance, object run)
    {
        HollowGlobals.Log("\n====== 🌐 多人读档雷达 (Host)：侦测到界面加载！ ======");

        // 1. 极其精准地获取背景容器
        var bgContainer = Traverse.Create(__instance).Field("_bgContainer").GetValue<Godot.Control>();
        if (bgContainer == null) return;

        // 2. 查户口：利用反射从 run 数据里强行提取角色 ID
        string charId = "";
        try {
            // 盲猜 run 里面有个 Character 字段，拿到它的 Id (长官如果报错，可在 dnSpy 确认 SerializableRun 的字段)
            var characterObj = Traverse.Create(run).Property("Character").GetValue() ?? Traverse.Create(run).Field("Character").GetValue();
            charId = Traverse.Create(characterObj).Property("Id").GetValue<string>() ?? Traverse.Create(characterObj).Field("Id").GetValue<string>();
            charId = charId ?? Traverse.Create(run).Field("CharacterId").GetValue<string>(); 
        } catch { }

        // 如果拿不到 ID，或者拿到的不是咱们的目标骨妹，直接撤退！
        if (!string.Equals(charId, "Necrobinder", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        // 3. 极其粗暴地替换背景大图
        foreach (Godot.Node child in bgContainer.GetChildren())
        {
            if (child is Godot.CanvasItem canvasItem) canvasItem.Hide();
        }

        if (HollowGlobals.SelectBigTexture != null)
        {
            var existingRect = bgContainer.GetNodeOrNull<Godot.TextureRect>("HollowKnight_SelectBg");
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
                bgContainer.AddChild(textureRect);
            }
        }
    }
}

// ==========================================
// 🌐 多人读档界面 (客机端)：替换背景大立绘
// ==========================================
[HarmonyPatch(typeof(MegaCrit.Sts2.Core.Nodes.Screens.CharacterSelect.NMultiplayerLoadGameScreen), "InitializeAsClient")] // 注意你的命名空间
internal static class NMultiplayerLoadGameScreen_InitializeAsClient_Patch
{
    private static void Postfix(Godot.Node __instance, object message)
    {
        HollowGlobals.Log("\n====== 🌐 多人读档雷达 (Client)：侦测到界面加载！ ======");

        var bgContainer = Traverse.Create(__instance).Field("_bgContainer").GetValue<Godot.Control>();
        if (bgContainer == null) return;

        // 客机端的查户口：从 message (ClientLoadJoinResponseMessage) 里提取 ID
        string charId = "";
        try {
            // 客机端的存档信息通常包得很深，可能是 message.Run.Character.Id 
            var runObj = Traverse.Create(message).Property("Run").GetValue() ?? Traverse.Create(message).Field("Run").GetValue();
            var characterObj = Traverse.Create(runObj).Property("Character").GetValue() ?? Traverse.Create(runObj).Field("Character").GetValue();
            charId = Traverse.Create(characterObj).Property("Id").GetValue<string>() ?? Traverse.Create(characterObj).Field("Id").GetValue<string>();
        } catch { }

        if (!string.Equals(charId, "Necrobinder", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(charId, HollowGlobals.TargetCharacterId, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        // 执行同样的换背景战术
        foreach (Godot.Node child in bgContainer.GetChildren())
        {
            if (child is Godot.CanvasItem canvasItem) canvasItem.Hide();
        }

        if (HollowGlobals.SelectBigTexture != null)
        {
            var existingRect = bgContainer.GetNodeOrNull<Godot.TextureRect>("HollowKnight_SelectBg");
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
                bgContainer.AddChild(textureRect);
            }
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