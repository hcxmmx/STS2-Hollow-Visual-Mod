using Godot.Bridge;
using HarmonyLib;
using MegaCrit.Sts2.Core.Logging;
using MegaCrit.Sts2.Core.Modding;

namespace Hcxmmx.HollowKnightMod.Scripts;

// [ModInitializer]: 极其关键的注册属性，让游戏引擎在启动时能瞬间找到咱们的 Mod
[ModInitializer(nameof(Init))]
public class Entry
{
    public static void Init()
    {
        // 1. 极其唯一的 Harmony ID 点火，确保不会和天子、咲夜或其他人的 Mod 冲突
        var harmony = new Harmony(HollowGlobals.HarmonyId);
        harmony.PatchAll();

        // 2. 极其关键的脚本桥接：使得 .tscn 场景文件可以正确识别并挂载咱们写的 C# 脚本
        ScriptManagerBridge.LookupScriptsInAssembly(typeof(Entry).Assembly);

        // 3. 极其响亮的启动播报
        HollowGlobals.Log("====================================");
        HollowGlobals.Log("Hollow Knight Project: 小骑士与纯粹容器极其震撼地加入战场！");
        HollowGlobals.Log("====================================");

        Log.Info("Hollow Knight Mod initialized successfully!");
    }
}