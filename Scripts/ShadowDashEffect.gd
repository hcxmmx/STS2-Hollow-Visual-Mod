extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
var trails: Array[Sprite2D] = []
var recharge: Sprite2D
var time := -2.0
var caster_foot := Vector2.ZERO
var frames: Dictionary = {}

func _ready() -> void:
    for clip in ["KnightTrail", "KnightRecharge"]:
        frames[clip] = ASSETS.frames(clip)
    for index in range(2):
        var trail := Sprite2D.new()
        trail.region_enabled = true
        trail.region_rect = ASSETS.unions["KnightTrail"]
        trail.flip_h = true
        add_child(trail)
        trails.append(trail)
    recharge = Sprite2D.new()
    recharge.region_enabled = true
    recharge.region_rect = ASSETS.unions["KnightRecharge"]
    add_child(recharge)
    sample(-1.0)

func sample(clock: float) -> void:
    if clock < 0.0 and time == clock:
        return
    time = clock
    shadow_dash()

func shadow_dash() -> void:
    for index in range(trails.size()):
        var age := time - (0.10 + float(index) * 0.10)
        var sprite := trails[index]
        sprite.visible = age >= 0.0 and age < 0.36
        if not sprite.visible:
            continue
        var textures: Array = frames["KnightTrail"]
        sprite.texture = textures[mini(int(age / 0.028), textures.size() - 1)]
        sprite.position = caster_foot + Vector2(-48 - index * 26, -74)
        sprite.scale = Vector2.ONE * (225.0 / maxf(sprite.region_rect.size.x, 1.0))
        sprite.modulate = Color(0.82, 0.89, 1.0, (0.84 if index == 0 else 0.45) * (1.0 - smoothstep(0.23, 0.36, age)))
    var age := time - 0.43
    recharge.visible = age >= 0.0 and age < 0.31
    if recharge.visible:
        var textures: Array = frames["KnightRecharge"]
        recharge.texture = textures[clampi(20 - int(age / 0.31 * 20.0), 0, 20)]
        recharge.position = caster_foot + Vector2(15, -65)
        recharge.scale = Vector2.ONE * (lerpf(155.0, 90.0, age / 0.31) / recharge.region_rect.size.x)
        recharge.modulate = Color(0.88, 0.92, 1.0, 0.85 * (1.0 - smoothstep(0.20, 0.31, age)))

