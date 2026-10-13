extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")

const DURATION := 0.85
@export var pattern := 0
var caster_offset := Vector2(-600, 65)
var show_impact := false
var origin := Vector2.ZERO
var target := Vector2.ZERO
var timeline := -1.0
var textures: Array[Texture2D] = []
var flash_textures: Array[Texture2D] = []
var wave: Sprite2D
var flash: Sprite2D
static var region_cache := Rect2()
static var flash_regions: Array[Rect2] = []
var wave_scale := 1.0

func launch_time() -> float:
    return 0.24 if pattern == 0 else 0.29

func _ready() -> void:
    textures.assign(ASSETS.frames("ArcWave"))
    flash_textures.assign(ASSETS.frames("Flash"))
    if not region_cache.has_area():
        region_cache = ASSETS.unions["ArcWave"]
        for texture in flash_textures:
            flash_regions.append(ASSETS.region(texture))
    var facing := -1.0 if caster_offset.x > 0.0 else 1.0
    var height: float = [65.0, 95.0, 35.0][clampi(pattern, 0, 2)]
    origin = caster_offset + Vector2(110.0 * facing, -height)
    wave = Sprite2D.new()
    wave.region_enabled = true
    wave.region_rect = region_cache
    wave.flip_h = true
    wave.flip_v = pattern == 1
    var tilt: float = [deg_to_rad(-30.0), deg_to_rad(30.0), deg_to_rad(-65.0)][clampi(pattern, 0, 2)]
    wave.rotation = tilt + (target - origin).angle()
    wave_scale = 195.0 / region_cache.size.x
    add_child(wave)
    flash = Sprite2D.new()
    flash.region_enabled = true
    add_child(flash)
    sample(-1.0)

func sample(time: float) -> void:
    timeline = time
    var launch := launch_time()
    var arrival := launch + 0.20
    var forming := time >= launch - 0.045 and time < launch
    var flying := time >= launch and time < arrival
    var tail := time - arrival
    wave.visible = forming or flying or (tail >= 0.0 and tail < 0.26)
    wave.scale = Vector2.ONE * wave_scale
    wave.modulate = Color(0.90, 0.96, 1.0, 1.0)
    if forming:
        wave.position = origin
        wave.texture = textures[0]
        wave.modulate.a = smoothstep(launch - 0.045, launch, time) * 0.8
        wave.scale *= lerpf(0.72, 1.0, smoothstep(launch - 0.045, launch, time))
    elif flying:
        wave.position = origin.lerp(target, (time - launch) / 0.20)
        wave.texture = textures[1]
    elif tail >= 0.0:
        wave.position = target + (target - origin).normalized() * minf(tail * 460.0, 90.0)
        # Unselected arcs pass through and fade without a hit burst or fragments.
        wave.texture = textures[clampi(2 + int(tail / 0.043), 2, 7)] if show_impact else textures[1]
        wave.modulate.a = 1.0 - smoothstep(0.03, 0.26, tail)
    flash.visible = show_impact and tail >= 0.0 and tail < 0.18
    if flash.visible:
        var index := mini(int(tail / 0.045), 3)
        flash.texture = flash_textures[index]
        flash.region_rect = flash_regions[index]
        flash.position = target
        flash.rotation = -0.35
        flash.scale = Vector2.ONE * (95.0 / maxf(flash.region_rect.size.x, 1.0))
        flash.modulate = Color(0.9, 0.96, 1.0, 0.9 * (1.0 - tail / 0.18))
    queue_redraw()

func _draw() -> void:
    var launch := launch_time()
    var arrival := launch + 0.20
    var direction := (target - origin).normalized()
    var perpendicular := Vector2(-direction.y, direction.x)
    if timeline >= launch and timeline < arrival:
        var progress := (timeline - launch) / 0.20
        var head := origin.lerp(target, progress)
        for index in range(7):
            var fraction := float(index + 1) / 8.0
            var at := head - direction * (24.0 + fraction * minf(130.0, progress * 260.0))
            at += perpendicular * sin(float(index) * 2.3) * 32.0
            draw_line(at, at - direction * (8.0 + float(index % 3) * 5.0), Color(0.8, 0.9, 1.0, (1.0 - fraction) * 0.32), 1.2, true)
    var tail := timeline - arrival
    if show_impact and tail >= 0.0 and tail < 0.24:
        var spread := smoothstep(0.0, 0.24, tail)
        for index in range(9):
            var ray := Vector2.from_angle(float(index) * TAU / 9.0 + 0.25)
            var at := target + ray * lerpf(14.0, 72.0, spread)
            draw_line(at, at + ray * 13.0 * (1.0 - spread), Color(0.9, 0.96, 1.0, (1.0 - spread) * 0.55), 1.5, true)
