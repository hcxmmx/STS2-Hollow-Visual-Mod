extends Node2D

const BODY_STYLE = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyPresentation.gd")

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
const CLIPS := {"Idle":"KnightIdle", "Cast":"KnightSoulCast", "Quake":"KnightQuake", "DarkQuake":"KnightDarkQuake", "Jump":"KnightJump", "Up":"KnightUp"}
var body: Sprite2D
var anchor := Vector2.ZERO
var pose_frame := 0

func _ready() -> void:
    var idle: Texture2D = ASSETS.frames("KnightIdle")[0]
    var bounds: Rect2 = ASSETS.region(idle)
    anchor = Vector2(bounds.get_center().x, bounds.end.y) - idle.get_size() * 0.5
    anchor.x = -anchor.x
    body = Sprite2D.new()
    body.flip_h = true
    add_child(body)
    BODY_STYLE.attach(body, Vector2.ZERO, false)
    BODY_STYLE.set_ground(body, get_parent() as Node2D, 0.0)
    idle_at(0.0)

func pose(clip: String, frame: int, grounded: bool = false) -> void:
    var textures: Array = ASSETS.frames(CLIPS[clip])
    pose_frame = clampi(frame, 0, textures.size() - 1)
    body.texture = textures[pose_frame]
    body.position = -anchor
    if grounded:
        var region: Rect2 = ASSETS.region(body.texture)
        body.position.y -= region.end.y - body.texture.get_height() * 0.5 - anchor.y
    body.visible = true
    body.modulate = Color.WHITE

func idle_at(time: float) -> void:
    pose("Idle", int(fposmod(time, 0.5333) / 0.5333 * 9.0), true)
