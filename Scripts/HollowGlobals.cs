using System;
using System.Linq;
using Godot;

namespace Hcxmmx.HollowKnightMod.Scripts;

public static class HollowGlobals
{
    public static bool EnableDebugLog = true;
    public static bool IsInShop = false;
    public const string TargetCharacterId = "NECROBINDER";
    public const string HarmonyId = "sts2.hcxmmx.hollowknight.visuals";

    public const string KnightScenePath = "res://Hcxmmx_Hollow_Knight_Skin/Scenes/hollow_knight.tscn";
    public const string SeniorScenePath = "res://Hcxmmx_Hollow_Knight_Skin/Scenes/PureVessel.tscn";

    public static readonly PackedScene? KnightScenePreloaded = ResourceLoader.Load<PackedScene>(KnightScenePath);
    public static readonly PackedScene? SeniorScenePreloaded = ResourceLoader.Load<PackedScene>(SeniorScenePath);
    public const string TopBarIconPath = "res://Hcxmmx_Hollow_Knight_Skin/Assets/Avatar/character_icon_hollow.png";
    public const string TopBarOutlinePath = "res://Hcxmmx_Hollow_Knight_Skin/Assets/Avatar/character_icon_hollow_outline.png";

    public static readonly Texture2D? TopBarIconTexture = ResourceLoader.Load<Texture2D>(TopBarIconPath);
    public static readonly Texture2D? TopBarOutlineTexture = ResourceLoader.Load<Texture2D>(TopBarOutlinePath);
    public const string SelectBigImgPath = "res://Hcxmmx_Hollow_Knight_Skin/Assets/Bg/Hollowbg.png";
    public static readonly Texture2D? SelectBigTexture = ResourceLoader.Load<Texture2D>(SelectBigImgPath);

    public static readonly Random Rng = new Random();

    // ==========================================
    // ⚔️ 皇家连招兵器库 (动作池全家桶 - 绝对统一管理)
    // ==========================================
    // 🚨 1. 入场盲盒池
    public static readonly string[] KnightIntroPool = { 
        "Challenge", "Lantern_Run", "Map_Run" 
    };

    // 🚨 2. 攻击盲盒池
    public static readonly string[] KnightAttackPool = { 
        "Charge_Slash", "Cyclone_Slash", "Dash_Slash", "Nail_Slash", "Scream", "Shadow_Dash" 
    };

    // 🚨 3. 技能盲盒池
    public static readonly string[] KnightSkillPool = { 
        "Cast", "Cast_Level", "Focus" ,"Collect","Collect_Shadow"
    };

    // ==========================================
    // 🎇 极其暴力的子节点特效清洗池
    // ==========================================
    public static readonly string[] VfxChildPool =
    {
        "Knight_VFX",     // 蓄力斩的那个（根据你之前的截图）
        "Cyclone_Slash",  // 旋风斩
        "Dashv",          // 冲刺
        "Dash_Slash",     // 冲刺斩
        "Scream",         // 尖叫
        "Charge_Slash"    // 冲锋
        // 如果长官还有新增的特效，直接把名字极其干脆地加在下面！
    };

    // 🚨 极其优雅的终极武器库：{ "本体动作名", 极其独立的专属特效图纸 }
    // 以后加一百个新绝招，也只需要在这里加一行！
    public static readonly System.Collections.Generic.Dictionary<string, PackedScene?> SeniorSkillMap = new()
    {
        { "Dash", null },                  // 没特效的动作填 null
        { "Slashes", null },
        { "Shoot", null },               
        { "Down_Slam", GD.Load<PackedScene>("res://Hcxmmx_Hollow_Knight_Skin/Scenes/VFX_GroundSpikes.tscn") }, 
        { "Dart_Shoot", GD.Load<PackedScene>("res://Hcxmmx_Hollow_Knight_Skin/Scenes/VFX_SwordRain.tscn") }
    };

    public static readonly string[] SeniorSkillKeys = SeniorSkillMap.Keys.ToArray();

    public static bool IsKnightDead = false;


    // 极其方便的日志输出
    public static void Log(string message)
    {
        if (!EnableDebugLog) return;
        GD.Print($"[Hollow_Radar] 📡 {message}");
    }

    public static string? GetCharacterEntry(object? model)
    {
        if (model == null) return null;

        var modelTraverse = HarmonyLib.Traverse.Create(model);
        var idObj = modelTraverse.Property("Id").GetValue()
            ?? modelTraverse.Field("Id").GetValue();
        if (idObj == null) return null;

        var idTraverse = HarmonyLib.Traverse.Create(idObj);
        return idTraverse.Property("Entry").GetValue<string>()
            ?? idTraverse.Field("Entry").GetValue<string>();
    }

    public static T? FindFirstNode<T>(Node root, Func<T, bool> predicate) where T : Node
    {
        foreach (Node child in root.GetChildren())
        {
            if (child is T typedChild && predicate(typedChild)) return typedChild;

            var found = FindFirstNode(child, predicate);
            if (found != null) return found;
        }

        return null;
    }

}