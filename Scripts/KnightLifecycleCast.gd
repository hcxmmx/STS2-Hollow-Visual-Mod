extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
const SHADE_SHADER = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/KnightVoidShade.gdshader")
const CLIPS := {"Idle": "KnightIdle", "Death": "KnightDeath", "Shade": "KnightShade", "Burst": "KnightVoidBurst", "Wake": "KnightWake", "Flash": "Flash"}
var body: Sprite2D
var ghost: Sprite2D
var burst: Sprite2D
var flash: Sprite2D
var state := "alive"
var clock := 0.0
var anchor := Vector2.ZERO
var mask_origin := Vector2(6, -91)

func _ready() -> void:
    var reference: Texture2D = ASSETS.frames("KnightIdle")[0]
    var bounds: Rect2 = ASSETS.region(reference)
    anchor = Vector2(bounds.get_center().x, bounds.end.y) - reference.get_size() * 0.5
    anchor.x = -anchor.x
    body = Sprite2D.new()
    body.flip_h = true
    add_child(body)
    ghost = cropped_sprite()
    # Use sibling order: above the stage background and behind the living body.
    move_child(ghost, 0)
    burst = cropped_sprite()
    flash = cropped_sprite()
    var material := ShaderMaterial.new()
    material.shader = SHADE_SHADER
    ghost.material = material
    burst.material = material
    clear()

func cropped_sprite() -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.region_enabled = true
    sprite.flip_h = true
    add_child(sprite)
    return sprite

func pose(clip: String, frame: int, grounded := false) -> void:
    var textures: Array = ASSETS.frames(CLIPS[clip])
    body.texture = textures[clampi(frame, 0, textures.size() - 1)]
    body.position = -anchor
    body.scale = Vector2.ONE
    body.rotation = 0.0
    body.modulate = Color.WHITE
    body.visible = true
    if grounded:
        var region: Rect2 = ASSETS.region(body.texture)
        body.position.y -= region.end.y - body.texture.get_height() * 0.5 - anchor.y

func crop_pose(sprite: Sprite2D, clip: String, frame: int, at: Vector2, size: float, as_foot := false) -> void:
    var textures: Array = ASSETS.frames(CLIPS[clip])
    sprite.texture = textures[clampi(frame, 0, textures.size() - 1)]
    sprite.region_rect = ASSETS.unions[CLIPS[clip]]
    var area: Rect2 = ASSETS.region(sprite.texture)
    var pivot := Vector2(area.get_center().x, area.end.y) if as_foot else area.get_center()
    var offset := pivot - sprite.region_rect.get_center()
    offset.x = -offset.x
    sprite.position = at - offset * size
    sprite.scale = Vector2.ONE * size
    sprite.visible = true

func shade(time: float, alpha: float) -> void:
    crop_pose(ghost, "Shade", int(fposmod(time, 0.8) / 0.8 * 12.0), Vector2(0, -8 - sin(time * 2.8) * 2.0), 0.82, true)
    ghost.modulate = Color(0.88, 0.94, 1.0, alpha)

func sample(mode: String, time: float) -> void:
    state = mode
    clock = maxf(time, 0.0)
    ghost.visible = false
    burst.visible = false
    flash.visible = false
    body.visible = false
    visible = true
    if state == "death":
        death_pose()
    elif state == "revive":
        revive_pose()
    queue_redraw()

func clear() -> void:
    state = "alive"
    clock = 0.0
    visible = false
    for sprite in [body, ghost, burst, flash]:
        sprite.visible = false
    queue_redraw()

func death_pose() -> void:
    if clock < 0.86:
        var frame := mini(int(clock / 0.64 * 14.0), 13)
        pose("Death", frame)
        body.position.y -= smoothstep(0.10, 0.46, clock) * 14.0
        body.position.y += smoothstep(0.64, 0.86, clock) * 18.0
        body.modulate.a = 1.0 - smoothstep(0.65, 0.86, clock)
    if clock >= 0.61 and clock < 0.77:
        crop_pose(flash, "Flash", mini(int((clock - 0.61) / 0.04), 3), mask_origin, 0.46)
        flash.modulate = Color(0.85, 0.93, 1.0, (1.0 - (clock - 0.61) / 0.16) * 0.76)
    if clock >= 0.65 and clock < 0.95:
        crop_pose(burst, "Burst", mini(int((clock - 0.65) / 0.09), 2), Vector2(0, -43), 0.70)
        burst.modulate = Color(0.88, 0.94, 1.0, 1.0 - smoothstep(0.78, 0.95, clock))
    if clock >= 0.78:
        shade(clock - 0.78, smoothstep(0.78, 1.10, clock) * 0.52)

func revive_pose() -> void:
    if clock < 0.30:
        shade(clock + 1.0, (1.0 - smoothstep(0.02, 0.30, clock)) * 0.52)
        var progress := smoothstep(0.0, 0.30, clock)
        var destination := Vector2(0, -60)
        ghost.position = destination + (ghost.position - destination) * (1.0 - progress * 0.7)
        ghost.scale *= 1.0 - progress * 0.7
    if clock >= 0.23 and clock < 0.40:
        crop_pose(flash, "Flash", mini(int((clock - 0.23) / 0.04), 3), Vector2(0, -69), 0.46)
        flash.modulate = Color(0.90, 0.96, 1.0, (1.0 - (clock - 0.23) / 0.17) * 0.8)
    if clock >= 0.27:
        if clock < 0.62:
            pose("Wake", mini(int((clock - 0.27) / 0.07), 4), true)
            body.modulate.a = smoothstep(0.27, 0.34, clock)
        else:
            pose("Idle", int(fposmod(clock - 0.62, 0.5333) / 0.5333 * 9.0), true)

func _draw() -> void:
    if state == "death" and clock >= 0.64 and clock < 1.12:
        var progress := (clock - 0.64) / 0.48
        for index in range(7):
            var angle := float(index) * TAU / 7.0 + 0.35
            var direction := Vector2.from_angle(angle)
            var point := mask_origin + direction * (10 + progress * 48) + Vector2(0, progress * progress * 25)
            var size := (1.0 - progress) * (2.0 + index % 3)
            var cross := direction.orthogonal() * size * 0.4
            draw_colored_polygon(PackedVector2Array([point + direction * size, point + cross, point - direction * size, point - cross]), Color(0.88, 0.93, 1.0, (1.0 - progress) * 0.65))
    elif state == "revive" and clock < 0.30:
        var progress := smoothstep(0.0, 0.30, clock)
        for index in range(6):
            var direction := Vector2.from_angle(float(index) * TAU / 6.0 + 0.3)
            var point := Vector2(0, -63) + direction * (1.0 - progress) * 66
            draw_circle(point, (1.0 - progress) * 1.6 + 0.5, Color(0.79, 0.88, 1.0, sin(progress * PI) * 0.68))
