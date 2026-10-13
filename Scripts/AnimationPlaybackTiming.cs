using MegaCrit.Sts2.Core.Saves;
using MegaCrit.Sts2.Core.Settings;

namespace Hcxmmx.HollowKnightMod.Scripts;

internal static class AnimationPlaybackTiming
{
    // The approved previews define 1x, including when the game uses Fast mode.
    // Damage callbacks select impact targets; they do not set animation speed.
    public const float StandardSpeed = 1.5f;
    public const float InstantSpeed = 4f;

    public static float CurrentSpeed =>
        SaveManager.Instance.PrefsSave.FastMode == FastModeType.Instant ? InstantSpeed : StandardSpeed;
}
