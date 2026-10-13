extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
var show_impact := false

var frames: Dictionary = {}
var focus_frames: Array = []


var time := -1.0
var target_center := Vector2.ZERO


var ring: Sprite2D
var rune: Sprite2D
var glow: Sprite2D
var flash: Sprite2D



func _ready() -> void:
    frames["Flash"] = ASSETS.frames("Flash")
    focus_frames = ASSETS.frames("Focus")
    ring = make_sprite(focus_frames[4], 210.0)
    rune = make_sprite(focus_frames[5], 168.0)
    glow = make_sprite(focus_frames[0], 220.0)
    flash = Sprite2D.new()
    flash.region_enabled = true
    add_child(flash)
    target_center = Vector2.ZERO
    sample(-1.0)

func make_sprite(texture: Texture2D, diameter: float) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.texture = texture
    sprite.region_enabled = true
    sprite.region_rect = ASSETS.regions[texture]
    sprite.scale = Vector2.ONE * diameter / maxf(sprite.region_rect.size.y, 1.0)
    add_child(sprite)
    return sprite

func sample(clock: float) -> void:
    time = clock
    for sprite in [ring, rune, glow, flash]:
        sprite.visible = false
    focus()
    if not show_impact and time >= 0.50:
        rune.visible = false
        glow.visible = false
        flash.visible = false
        ring.scale = Vector2.ONE * 185.0 / ring.region_rect.size.y
        ring.modulate.a = 0.45 * (1.0 - smoothstep(0.50, 0.68, time))
    queue_redraw()

func focus() -> void:
    var hit := 0.50
    var tail := time - hit
    if time >= 0.05 and time < hit:
        var appear := smoothstep(0.05, 0.20, time)
        var squeeze := smoothstep(0.33, hit, time)
        ring.visible = true
        ring.position = target_center
        ring.texture = focus_frames[1 + mini(int(maxf(time - 0.05, 0.0) / 0.055), 3)]
        ring.scale = Vector2.ONE * (lerpf(235.0, 185.0, squeeze) / ring.region_rect.size.y)
        ring.modulate = Color(0.88, 0.95, 1.0, appear * lerpf(0.45, 0.92, squeeze))
        rune.visible = true
        rune.position = target_center
        rune.scale = Vector2.ONE * (lerpf(178.0, 152.0, squeeze) / rune.region_rect.size.y)
        rune.modulate = Color(0.88, 0.95, 1.0, appear * (0.44 + 0.13 * sin(time * 22.0)))
    elif tail >= 0.0 and tail < 0.32:
        ring.visible = true
        ring.position = target_center
        ring.texture = focus_frames[4]
        ring.scale = Vector2.ONE * (lerpf(185.0, 385.0, smoothstep(0.0, 0.25, tail)) / ring.region_rect.size.y)
        ring.modulate = Color(0.90, 0.97, 1.0, 0.90 * (1.0 - smoothstep(0.025, 0.28, tail)))
        rune.visible = tail < 0.18
        rune.position = target_center
        rune.scale = Vector2.ONE * (lerpf(152.0, 215.0, tail / 0.18) / rune.region_rect.size.y)
        rune.modulate = Color(0.94, 0.98, 1.0, 0.70 * (1.0 - tail / 0.18))
        glow.visible = tail < 0.21
        glow.position = target_center
        glow.scale = Vector2.ONE * (lerpf(190.0, 325.0, tail / 0.21) / glow.region_rect.size.y)
        glow.modulate = Color(0.92, 0.97, 1.0, 0.65 * (1.0 - tail / 0.21))
    impact(hit, 135.0)

func impact(hit: float, diameter: float) -> void:
    var tail := time - hit
    flash.visible = tail >= 0.0 and tail < 0.20
    if flash.visible:
        var textures: Array = frames["Flash"]
        flash.texture = textures[mini(int(tail / 0.05), 3)]
        flash.region_rect = ASSETS.regions[flash.texture]
        flash.position = target_center
        flash.rotation = -0.3
        flash.scale = Vector2.ONE * diameter / maxf(flash.region_rect.size.x, 1.0)
        flash.modulate = Color(0.92, 0.97, 1.0, 0.95 * (1.0 - tail / 0.20))

func _draw() -> void:
    var tail := time - 0.50
    if show_impact and tail >= 0.0 and tail < 0.28:
        var progress := smoothstep(0.0, 0.28, tail)
        for index in range(14):
            var ray := Vector2.from_angle(float(index) * TAU / 14.0 + 0.13)
            var at := target_center + ray * lerpf(55.0, 185.0, progress)
            draw_line(at, at + ray * 21.0 * (1.0 - progress), Color(0.9, 0.97, 1.0, (1.0 - progress) * 0.7), 1.5, true)
