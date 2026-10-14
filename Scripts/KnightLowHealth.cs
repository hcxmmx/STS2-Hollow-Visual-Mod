using System;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Models;

namespace Hcxmmx.HollowKnightMod.Scripts;

internal static class KnightLowHealth
{
    public static void PlayAction(Node2D? root, string action)
    {
        if (root == null) return;
        var controller = root.GetNodeOrNull<Node>("IdleController");
        if (controller != null)
        {
            controller.Call("play_action", action);
            return;
        }
        var player = root.GetNodeOrNull<AnimationPlayer>("AnimationPlayer");
        player?.ClearQueue();
        player?.Play(action);
        if (action != "Death" && action != "Idle_Map") player?.Queue("Idle");
    }

    public static void RequestIdle(Node2D? root)
    {
        root?.GetNodeOrNull<Node>("IdleController")?.Call("request_idle");
    }

    public static void RequestVictory(Node2D? root)
    {
        if (!GodotObject.IsInstanceValid(root) || root!.IsQueuedForDeletion()) return;
        var controller = root.GetNodeOrNull<Node>("IdleController");
        if (controller != null) controller.Call("request_victory");
        else PlayAction(root, "Idle_Map");
    }

    public static void Revive(Node2D? root)
    {
        root?.GetNodeOrNull<Node>("IdleController")?.Call("play_revive");
    }

    // Use the character model's own condition rather than duplicating a threshold.
    private static readonly System.Reflection.MethodInfo? LowHealthGetter =
        AccessTools.PropertyGetter(typeof(CharacterModel), "IsLowHealth");

    public static void Bind(Creature creature, Node2D root)
    {
        var controller = root.GetNodeOrNull<Node>("IdleController");
        var character = creature.Player?.Character;
        if (controller == null || character == null) return;
        if (LowHealthGetter?.Invoke(character, null) is not Func<Creature, bool> isLowHealth)
        {
            GD.PushWarning("Hollow Knight: official low-health condition was not found.");
            return;
        }

        void Refresh(int _, int __)
        {
            if (GodotObject.IsInstanceValid(controller) && !controller.IsQueuedForDeletion())
                controller.Call("set_low_health", isLowHealth(creature));
        }

        creature.CurrentHpChanged += Refresh;
        creature.MaxHpChanged += Refresh;
        root.TreeExiting += () =>
        {
            creature.CurrentHpChanged -= Refresh;
            creature.MaxHpChanged -= Refresh;
        };
        Refresh(0, 0);
    }
}
