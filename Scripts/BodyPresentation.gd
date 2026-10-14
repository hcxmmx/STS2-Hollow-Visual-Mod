extends Node2D

const DEPTH = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyDepth.gdshader")
const METRICS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyStyleMetrics.gd")
const STYLE_STRENGTH := 0.75
static var shadow_textures: Array[Texture2D] = []
var body: Node2D
var shading: ShaderMaterial
var shadow_root: Node2D
var ground_space: Node2D
var ground_y := 0.0
var foot := Vector2.ZERO
var last_texture: Texture2D
var last_flip := false
var prime := false

static func attach(sprite: Node2D, ground_foot: Vector2, senior: bool) -> Node2D:
    var script: Script = load("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyPresentation.gd")
    var presentation: Node2D = script.new()
    presentation.body = sprite
    presentation.prime = senior
    presentation.foot = ground_foot
    presentation.ground_space = sprite.get_parent() as Node2D
    presentation.ground_y = ground_foot.y
    sprite.set_meta("body_presentation", presentation)
    sprite.get_parent().add_child(presentation)
    # Relative sibling order keeps shadows above the stage and below the body.
    sprite.get_parent().move_child(presentation, 0)
    return presentation

static func set_ground(sprite: Node2D, space: Node2D, height: float) -> void:
    var presentation: Node2D = sprite.get_meta("body_presentation", null)
    if is_instance_valid(presentation):
        presentation.ground_space = space
        presentation.ground_y = height

func _ready() -> void:
    process_priority = 100
    shading = ShaderMaterial.new()
    shading.shader = DEPTH
    shading.set_shader_parameter("strength", STYLE_STRENGTH)
    body.material = shading
    shadow_root = Node2D.new()
    add_child(shadow_root)
    if shadow_textures.is_empty():
        for core in [false, true]:
            var gradient := Gradient.new()
            gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.60, 1.0])
            gradient.colors = PackedColorArray([Color(0,0.008,0.010,0.58 if core else 0.32), Color(0,0.008,0.010,0.39 if core else 0.24), Color(0,0.008,0.010,0.10), Color(0,0,0,0)])
            var texture := GradientTexture2D.new()
            texture.gradient = gradient
            texture.width = 256
            texture.height = 128
            texture.fill = GradientTexture2D.FILL_RADIAL
            texture.fill_from = Vector2(0.5, 0.5)
            texture.fill_to = Vector2(0.5, 1.0)
            shadow_textures.append(texture)
    var width := 388.8889 if prime else 70.9091
    var height := 40.2778 if prime else 11.8182
    for index in range(2):
        var sprite := Sprite2D.new()
        sprite.texture = shadow_textures[index]
        var size_factor := 0.5 if index == 1 else 1.0
        sprite.scale = Vector2(width / 256.0, height / 128.0) * size_factor
        shadow_root.add_child(sprite)
    shadow_root.visible = false

func _process(_delta: float) -> void:
    if not is_instance_valid(body) or not is_instance_valid(ground_space):
        shadow_root.visible = false
        return
    var texture: Texture2D
    var flipped: bool = body.get("flip_h")
    if body is AnimatedSprite2D:
        texture = body.sprite_frames.get_frame_texture(body.animation, body.frame)
    else:
        texture = body.get("texture")
    if texture == null:
        shadow_root.visible = false
        return
    if texture != last_texture or flipped != last_flip:
        _update_shading(texture, flipped)
        last_texture = texture
        last_flip = flipped
    shadow_root.visible = body.is_visible_in_tree()
    if not shadow_root.visible:
        return
    var data: Dictionary = METRICS.FRAMES.get(texture.resource_path, {})
    var bounds: Array = data.get("bounds", [0,0,texture.get_width(),texture.get_height()])
    var foot_y := float(bounds[1]) + float(bounds[3]) - texture.get_height() * 0.5
    var at := body.to_global(Vector2(foot.x - body.position.x, foot_y))
    var ground := ground_space.to_local(at)
    var elevation := maxf(ground_y - ground.y, 0.0) * ground_space.global_transform.y.length()
    ground.y = ground_y
    var transform := body.global_transform
    var ratio := clampf(elevation / maxf(130.0 * transform.y.length(), 1.0), 0.0, 1.0)
    var shrink := lerpf(1.0, 0.58, ratio)
    # Keep the footprint flat even when the animation rotates or mirrors the body.
    shadow_root.global_transform = Transform2D(Vector2(transform.x.length() * shrink, 0), Vector2(0, transform.y.length() * shrink), ground_space.to_global(ground) + Vector2(0, 3.0 * transform.y.length()))
    shadow_root.modulate.a = body.modulate.a * body.self_modulate.a * lerpf(1.0, 0.33, ratio)

func _update_shading(texture: Texture2D, flipped: bool) -> void:
    var data: Dictionary = METRICS.FRAMES.get(texture.resource_path, {})
    var bounds: Array = data.get("bounds", [0,0,texture.get_width(),texture.get_height()])
    _set_area("shape", bounds, texture, flipped)
    _set_area("face", data.get("face", [0,0,1,1]), texture, flipped)
    _set_area("cloth", data.get("cloth", bounds), texture, flipped)
    shading.set_shader_parameter("face_valid", bool(data.get("face_valid", false)))
    shading.set_shader_parameter("mirrored", flipped)

func _set_area(kind: String, values: Array, texture: Texture2D, flipped: bool) -> void:
    var origin := Vector2(float(values[0]), float(values[1])) - texture.get_size() * 0.5
    var extent := Vector2(float(values[2]), float(values[3]))
    if flipped:
        origin.x = -origin.x - extent.x
    shading.set_shader_parameter(kind + "_min", origin)
    shading.set_shader_parameter(kind + "_size", extent)
