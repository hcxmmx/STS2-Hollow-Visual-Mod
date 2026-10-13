extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
const CLIPS := {"Portal":"KnightPortal", "Soul":"KnightSoul", "UpEffect":"KnightUpEffect", "Flash":"Flash"}
# Visible nail tips in the five body frames; these are not texture-canvas pivots.
const UP_NAIL_TIPS := [Vector2(207, 146), Vector2(251, 173), Vector2(240, 172), Vector2(232, 167), Vector2(240, 141)]
# End of the bright, descending branch in each native effect frame.
const UP_ARC_ENDS := [Vector2(150, 154), Vector2(143, 180)]
var show_home := true
var show_travel := true
var show_impact := false
var target_contact := Vector2(1016, 541)
var mode := 0
var clock := -1.0
var caster := Vector2(330, 620)
var target_foot := Vector2(1060, 620)
var target_center := Vector2(1060, 541)
var portal: Sprite2D
var soul: Sprite2D
var bloom: Sprite2D
var ground_wave: Sprite2D
var slash: Sprite2D
var flash: Sprite2D
var sprites: Array[Sprite2D] = []
var wave_position := Vector2.ZERO
var soul_position := Vector2.ZERO

func _ready() -> void:
    portal = make_sprite("Portal")
    soul = make_sprite("Soul")
    bloom = make_sprite("Portal")
    ground_wave = make_sprite("Portal")
    slash = make_sprite("UpEffect")
    slash.flip_h = true
    flash = make_sprite("Flash")
    sample(0, -1.0)

func make_sprite(clip: String) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.region_enabled = true
    sprite.region_rect = ASSETS.unions[CLIPS[clip]]
    add_child(sprite)
    sprites.append(sprite)
    return sprite

func set_frame(sprite: Sprite2D, clip: String, frame: int) -> void:
    var frames: Array = ASSETS.frames(CLIPS[clip])
    sprite.texture = frames[clampi(frame, 0, frames.size() - 1)]

func hit_time() -> float:
    return [0.88, 0.60, 0.09][mode]

func sample(action: int, time: float) -> void:
    mode = action
    clock = time
    for sprite in sprites:
        sprite.visible = false
        sprite.modulate = Color.WHITE
        sprite.rotation = 0.0
        sprite.scale = Vector2.ONE
    if mode == 0:
        quake()
    elif mode == 1:
        shadow_soul()
    else:
        upward_slash()
    var tail := clock - hit_time()
    flash.visible = show_impact and tail >= 0.0 and tail < 0.18
    if flash.visible:
        set_frame(flash, "Flash", mini(int(tail / 0.045), 3))
        flash.region_rect = ASSETS.region(flash.texture)
        flash.position = target_foot + Vector2(0, -26) if mode == 0 else target_contact
        flash.scale = Vector2.ONE * (90.0 / maxf(flash.region_rect.size.x, 1.0))
        flash.rotation = 0.4 if mode == 0 else -0.35
        flash.modulate = Color(0.88, 0.96, 1.0, 0.94 * (1.0 - tail / 0.18))
    queue_redraw()

func quake() -> void:
    var tail := clock - 0.60
    if show_home and tail >= 0.0 and tail < 0.38:
        bloom.visible = true
        set_frame(bloom, "Portal", 3 + mini(int(tail / 0.055), 5))
        bloom.position = caster + Vector2(0, -15)
        bloom.rotation = PI * 0.5
        var progress := smoothstep(0.0, 0.30, tail)
        bloom.scale = Vector2(0.22, lerpf(0.55, 1.65, progress))
        bloom.modulate.a = (1.0 - smoothstep(0.16, 0.38, tail)) * 0.82
    if show_travel and tail >= 0.02 and tail < 0.48:
        var progress := clampf((tail - 0.02) / 0.26, 0.0, 1.0)
        wave_position = caster.lerp(target_foot, progress)
        ground_wave.visible = true
        set_frame(ground_wave, "Portal", 4 + mini(int(maxf(tail - 0.28, 0.0) / 0.04), 4))
        ground_wave.position = wave_position + Vector2(0, -17)
        ground_wave.rotation = PI * 0.5
        ground_wave.scale = Vector2(0.20, 0.88)
        ground_wave.modulate.a = 0.90 * (1.0 - smoothstep(0.28, 0.48, tail))

func shadow_soul() -> void:
    if show_home and clock >= 0.13 and clock < 0.53:
        portal.visible = true
        set_frame(portal, "Portal", mini(int((clock - 0.13) / 0.045), 8))
        portal.position = caster + Vector2(79, -78)
        portal.scale = Vector2(0.64, 0.60)
        portal.modulate.a = smoothstep(0.13, 0.22, clock) * (1.0 - smoothstep(0.36, 0.53, clock))
    if show_travel and clock >= 0.32 and clock < 0.84:
        soul.visible = true
        var progress := clampf((clock - 0.32) / 0.28, 0.0, 1.0)
        var native: Texture2D = ASSETS.frames("KnightSoul")[3]
        var front: float = (ASSETS.region(native).end.x - ASSETS.unions["KnightSoul"].get_center().x) * 0.72
        var origin := caster + Vector2(79, -78)
        var direction := (target_contact - origin).normalized()
        var endpoint := target_contact - direction * front
        soul_position = origin.lerp(endpoint, progress)
        soul.flip_h = direction.x < 0.0
        soul.rotation = direction.angle() - (PI if soul.flip_h else 0.0)
        if clock < 0.60:
            set_frame(soul, "Soul", mini(1 + int((clock - 0.32) / 0.040), 3))
        else:
            set_frame(soul, "Soul", 4 + mini(int((clock - 0.60) / 0.04), 5))
            soul_position += direction * (clock - 0.60) * 140.0
        soul.position = soul_position
        soul.scale = Vector2.ONE * 0.72
        soul.modulate.a = smoothstep(0.32, 0.35, clock) * (1.0 - smoothstep(0.69, 0.84, clock))

func upward_slash() -> void:
    # The arc appears with the actual strike pose, then contracts along the nail.
    if show_home and clock >= 0.06 and clock < 0.24:
        slash.visible = true
        set_frame(slash, "UpEffect", 0 if clock < 0.12 else 1)
        slash.modulate = Color(0.95, 0.98, 1.0, smoothstep(0.06, 0.07, clock) * (1.0 - smoothstep(0.16, 0.24, clock)))

func align_up_slash(body: Sprite2D, body_frame: int) -> void:
    if mode != 2 or not slash.visible:
        return
    var nail: Vector2 = UP_NAIL_TIPS[clampi(body_frame, 0, 4)] - body.texture.get_size() * 0.5
    var effect_frame := 0 if clock < 0.12 else 1
    var end: Vector2 = UP_ARC_ENDS[effect_frame] - ASSETS.unions["KnightUpEffect"].get_center()
    if body.flip_h:
        nail.x = -nail.x
        end.x = -end.x
    slash.global_transform = body.global_transform
    slash.flip_h = body.flip_h
    slash.global_position = body.to_global(nail) - slash.global_transform.basis_xform(end)

func _draw() -> void:
    if mode == 0:
        var tail := clock - 0.60
        if show_home and tail >= 0.0 and tail < 0.32:
            var progress := smoothstep(0.0, 0.32, tail)
            draw_set_transform(caster, 0.0, Vector2(1.0, 0.20))
            draw_arc(Vector2.ZERO, lerpf(18, 190, progress), 0.0, TAU, 64, Color(0.78, 0.88, 1.0, (1.0 - progress) * 0.78), 2.2, true)
            draw_set_transform(Vector2.ZERO)
            for index in range(10):
                var side := -1.0 if index % 2 == 0 else 1.0
                var point := caster + Vector2(side * (30 + index * 14) * progress, -sin(progress * PI) * (15 + index % 3 * 16))
                draw_line(point, point + Vector2(side * 9, -6), Color(0.42, 0.57, 0.76, (1.0 - progress) * 0.48), 2.0, true)
        if show_travel and tail >= 0.02 and tail < 0.28:
            draw_set_transform(wave_position + Vector2(0, -8), 0.0, Vector2(0.35, 1.0))
            draw_arc(Vector2.ZERO, 46, -PI * 0.5, PI * 0.5, 30, Color(0.75, 0.88, 1.0, 0.52), 1.7, true)
            draw_set_transform(Vector2.ZERO)
        var impact := clock - hit_time()
        if show_impact and impact >= 0.0 and impact < 0.28:
            draw_set_transform(target_foot, 0.0, Vector2(1.0, 0.22))
            draw_arc(Vector2.ZERO, lerpf(14, 140, smoothstep(0.0, 0.28, impact)), 0.0, TAU, 64, Color(0.82, 0.93, 1.0, (1.0 - impact / 0.28) * 0.75), 2.0, true)
            draw_set_transform(Vector2.ZERO)
    elif mode == 1:
        if show_travel and clock >= 0.32 and clock < 0.60:
            for index in range(6):
                var point := soul_position + Vector2(-28 - index * 20, sin(index * 2.3) * 16)
                draw_line(point, point + Vector2(-15, 0), Color(0.50, 0.66, 0.85, (1.0 - float(index) / 6.0) * 0.22), 1.0, true)
        var tail := clock - 0.60
        if show_impact and tail >= 0.0 and tail < 0.24:
            for index in range(8):
                var ray := Vector2.from_angle(float(index) * TAU / 8.0 + 0.20)
                var point := target_contact + ray * lerpf(10, 66, tail / 0.24)
                draw_line(point, point + ray * 10, Color(0.59, 0.77, 0.97, (1.0 - tail / 0.24) * 0.45), 1.5, true)
