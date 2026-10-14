extends Node2D

const BODY_STYLE = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyPresentation.gd")

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")

const SLASH_KEYS := [0.0, 0.04, 0.08, 0.12, 0.17, 0.24, 0.28, 0.31, 0.37]
var frames: Dictionary = {}
var body: Sprite2D
var anchor := Vector2.ZERO

func _ready() -> void:
    for clip in ["PrimeIdle", "PrimeRoar", "PrimeSlash", "PrimeTeleport", "PrimeJump", "PrimeSlam"]:
        frames[clip] = ASSETS.frames(clip)
    var idle: Texture2D = frames["PrimeIdle"][0]
    var bounds: Rect2 = ASSETS.regions[idle]
    anchor = Vector2(bounds.get_center().x, bounds.end.y) - idle.get_size() * 0.5
    body = Sprite2D.new()
    body.flip_h = false
    body.position = -anchor
    add_child(body)
    BODY_STYLE.attach(body, Vector2.ZERO, true)
    idle_at(0.0)

func pose(clip: String, frame: int) -> void:
    var textures: Array = frames[clip]
    body.texture = textures[clampi(frame, 0, textures.size() - 1)]
    body.position = -anchor
    body.visible = true
    body.modulate = Color.WHITE

func idle_at(time: float) -> void:
    var clip := "PrimeIdle"
    pose(clip, int(fposmod(time, 0.55) / 0.55 * frames[clip].size()))

func slash_at(time: float) -> void:
    var frame := 0
    for index in range(SLASH_KEYS.size()):
        if time >= SLASH_KEYS[index]:
            frame = index
    pose("PrimeSlash", frame)
