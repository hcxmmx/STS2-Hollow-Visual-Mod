extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")

enum Pattern { RAIN, FAN }
const DURATION := 0.98
const SWORD_COUNT := 7
@export var pattern := Pattern.RAIN
var caster_offset := Vector2(-380, 100)
var show_impact := false
var swords: Array[Node2D] = []
var glyphs: Array[Sprite2D] = []
var glows: Array[Sprite2D] = []
var impacts: Array[Sprite2D] = []
var shot_textures: Array[Texture2D] = []
var antic_textures: Array[Texture2D] = []
var flash_textures: Array[Texture2D] = []
var starts: Array[Vector2] = []
var ends: Array[Vector2] = []
var launches: Array[float] = []
var flights: Array[float] = []
var timeline := -1.0
static var shot_bounds_cache := Rect2()
static var antic_bounds_cache := Rect2()
static var flash_regions: Array[Rect2] = []

func _ready() -> void:
    shot_textures.assign(ASSETS.frames("SwordShot"))
    antic_textures.assign(ASSETS.frames("SwordAntic"))
    flash_textures.assign(ASSETS.frames("Flash"))
    if not shot_bounds_cache.has_area():
        shot_bounds_cache = ASSETS.unions["SwordShot"]
        antic_bounds_cache = ASSETS.unions["SwordAntic"]
        for texture in flash_textures:
            flash_regions.append(ASSETS.region(texture))
    var shot_bounds := shot_bounds_cache
    var antic_bounds := antic_bounds_cache
    for index in range(SWORD_COUNT):
        var holder := Node2D.new()
        add_child(holder)
        swords.append(holder)
        var glow := _sprite(antic_textures[2], antic_bounds, 0.19)
        glow.position.y = 48.0
        holder.add_child(glow)
        glows.append(glow)
        var glyph := _sprite(shot_textures[0], shot_bounds, 0.40)
        holder.add_child(glyph)
        glyphs.append(glyph)
        var flash := Sprite2D.new()
        flash.region_enabled = true
        add_child(flash)
        impacts.append(flash)
        if pattern == Pattern.RAIN:
            starts.append(Vector2(float(index - 3) * 39.0, -245.0 - float(absi(index - 3)) * 7.0))
            ends.append(Vector2(float(index - 3) * 14.0, float(index % 2) * 9.0))
            launches.append(0.34 + float(absi(index - 3)) * 0.052)
            flights.append(0.18)
        else:
            var angle := deg_to_rad(-160.0 + float(index) * 17.0)
            var facing := -1.0 if caster_offset.x > 0.0 else 1.0
            var arc := Vector2.from_angle(angle) * 132.0
            starts.append(caster_offset + Vector2(70.0 * facing, -140.0) + Vector2(arc.x * facing, arc.y))
            ends.append(Vector2(float(index - 3) * 7.0, float(index - 3) * 14.0))
            launches.append(0.36 + float(absi(index - 3)) * 0.012)
            flights.append(0.23)
    sample(-1.0)

func _sprite(texture: Texture2D, region: Rect2, size: float) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.texture = texture
    sprite.region_enabled = true
    sprite.region_rect = region
    sprite.scale = Vector2.ONE * size
    return sprite

func sample(time: float) -> void:
    timeline = time
    for index in range(swords.size()):
        var launch := launches[index]
        var flight := flights[index]
        var arrival := launch + flight
        var appear := float(absi(index - 3)) * 0.035
        var formation := smoothstep(appear, appear + 0.16, time)
        var holder := swords[index]
        var pass_time := time - arrival
        holder.visible = time >= appear and (time < arrival or (not show_impact and pass_time < 0.12))
        holder.rotation = (ends[index] - starts[index]).angle() + PI * 0.5
        if time < launch:
            var origin := starts[index] + Vector2(0, -18) if pattern == Pattern.RAIN else caster_offset + Vector2(70.0 * (-1.0 if caster_offset.x > 0.0 else 1.0), -140.0)
            holder.position = origin.lerp(starts[index], formation)
            holder.modulate = Color(0.88, 0.94, 1.0, formation)
            holder.scale = Vector2.ONE * lerpf(0.8, 1.0, formation)
            glyphs[index].texture = shot_textures[0]
            glows[index].texture = antic_textures[mini(int(maxf(time - appear, 0.0) / 0.055), 2)]
            glows[index].modulate = Color(0.85, 0.92, 1.0, 0.32 * formation)
        else:
            var progress := (time - launch) / flight
            holder.position = starts[index].lerp(ends[index], progress)
            holder.modulate = Color(1, 1, 1, 1.0 - smoothstep(0.0, 0.12, pass_time)) if pass_time >= 0.0 else Color.WHITE
            holder.scale = Vector2.ONE
            # Keep the ornate sword silhouette rigid in flight. The other source
            # frames change its profile too much for these deliberately clean paths.
            glyphs[index].texture = shot_textures[0]
            glows[index].visible = false
        if time < launch:
            glows[index].visible = true
        var hit_time := time - arrival
        var flash := impacts[index]
        flash.visible = show_impact and hit_time >= 0.0 and hit_time < 0.18
        if flash.visible:
            var flash_index := mini(int(hit_time / 0.045), 3)
            flash.texture = flash_textures[flash_index]
            flash.region_rect = flash_regions[flash_index]
            flash.position = ends[index]
            flash.rotation = float(index) * 0.7
            flash.scale = Vector2.ONE * (43.0 / maxf(flash.region_rect.size.x, 1.0))
            flash.modulate = Color(0.91, 0.96, 1.0, 0.72 * (1.0 - hit_time / 0.18))
    queue_redraw()

func _draw() -> void:
    for index in range(starts.size()):
        var elapsed := timeline - launches[index]
        if elapsed <= 0.0 or elapsed >= flights[index]:
            continue
        var direction := (ends[index] - starts[index]).normalized()
        var head := swords[index].position + direction * 34.0
        var length := minf(82.0, elapsed / flights[index] * 140.0)
        for piece in range(4):
            var start := head - direction * length * float(piece) / 4.0
            var finish := head - direction * length * float(piece + 1) / 4.0
            draw_line(start, finish, Color(0.77, 0.88, 1.0, 0.16 * (1.0 - float(piece) / 4.0)), 3.0 - float(piece) * 0.5, true)
