extends Node2D

const BODY_STYLE = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BodyPresentation.gd")

const ACTOR = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionActor.gd")
const FOCUS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/FocusBurstEffect.gd")
const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")
const GHOST_COLOR := Color(0.52, 0.66, 0.94, 0.40)
@export var kind := 0 # Focus / teleport slash / aerial slam
var controller: Node
var revision := -1
var broad_cast := false
var canceled := false
var playback_speed := 1.0
var body_speed := 1.0
var started := false
var elapsed := 0.0
var age := 0.0
var placed := false
var home: Node2D
var entries: Dictionary = {}
var target_feet: Dictionary = {}
var slam_offsets: Dictionary = {}
var flash_textures: Array = []
var clock := -1.0
var facing := 1.0

func _ready() -> void:
    home = new_actor()
    var anchor: Vector2 = home.get("anchor")
    for texture in ASSETS.frames("PrimeSlam"):
        slam_offsets[texture] = ASSETS.regions[texture].end.y - texture.get_height() * 0.5 - anchor.y
    flash_textures = ASSETS.frames("Flash")
    home.visible = false

func new_actor() -> Node2D:
    var actor := ACTOR.new()
    actor.scale = Vector2.ONE * 0.20
    add_child(actor)
    return actor

func first_hit() -> float:
    return [0.50, 0.70, 0.58][kind]

func duration() -> float:
    return [0.86, 1.30, 1.10][kind]

func bind_target_foot(key: int, at: Vector2) -> void:
    target_feet[key] = at

func add_target(key: int, center: Vector2, caster: Vector2, size: float) -> void:
    if entries.has(key):
        return
    if not placed:
        global_position = caster
        global_scale = Vector2.ONE * size * 1.25
        placed = true
        if is_instance_valid(controller):
            facing = signf(controller.get_parent().global_scale.x)
            if facing == 0.0:
                facing = 1.0
    var at: Vector2 = target_feet.get(key, center + Vector2(0, 70.0 * size))
    var ghost: Node2D
    var flash: Sprite2D
    if kind != 0:
        ghost = new_actor()
        flash = Sprite2D.new()
        flash.region_enabled = true
        add_child(flash)
        flash.visible = false
    var effect: Node2D
    if kind == 0:
        effect = FOCUS.new()
        effect.scale = Vector2.ONE * 0.625 # Approved .32 body preview -> .20 reference.
        add_child(effect)
    entries[key] = {"ghost": ghost, "flash": flash, "effect": effect,
        "foot": to_local(at), "center": to_local(center), "committed": false,
        "time": -1.0}
    if started:
        update_visuals()

func commit_target(key: int, center: Vector2, caster: Vector2, size: float) -> void:
    add_target(key, center, caster, size)
    var entry: Dictionary = entries[key]
    entry["center"] = to_local(center)
    if target_feet.has(key):
        entry["foot"] = to_local(target_feet[key])
    entry["committed"] = true
    update_visuals()

func start() -> void:
    if started or canceled:
        return
    started = true
    elapsed = 0.0
    if is_instance_valid(controller):
        revision = int(controller.get("action_revision"))
        controller.call("claim_special", self)
    update_visuals()

func cancel() -> void:
    if canceled:
        return
    canceled = true
    visible = false
    release_body(false)
    queue_free()

func release_body(finished: bool) -> void:
    if is_instance_valid(controller) and not controller.is_queued_for_deletion():
        controller.call("release_special", self, revision, finished)

func update_visuals() -> void:
    if not started or canceled:
        return
    # Keep the approved movement timeline continuous, even if damage arrives early.
    clock = elapsed
    home.visible = true
    home.position = Vector2.ZERO
    home.scale = Vector2(0.20 * facing, 0.20)
    home.call("idle_at", maxf(clock, 0.0))
    sample_home(clock)
    BODY_STYLE.set_ground(home.get("body"), self, 0.0)
    var done := clock >= duration()
    for key in entries:
        var entry: Dictionary = entries[key]
        var time: float = clock
        entry["time"] = time
        sample_target(entry, time)
        if time < duration():
            done = false
    queue_redraw()
    if done:
        visible = false
        release_body(true)
        queue_free()

func sample_home(time: float) -> void:
    if kind == 0:
        if time < 0.82:
            home.call("pose", "PrimeRoar", mini(int(time / 0.50 * 9.0), 11))
        return
    if kind == 1:
        if time < 0.18:
            home.call("pose", "PrimeTeleport", int(time / 0.18 * 5.0))
            home.get("body").modulate.a = 1.0 - smoothstep(0.10, 0.18, time)
        elif time < 1.12:
            home.get("body").visible = false
        elif time < 1.28:
            home.call("pose", "PrimeTeleport", 4 - int((time - 1.12) / 0.16 * 5.0))
            home.get("body").modulate.a = smoothstep(1.12, 1.20, time)
    else:
        if time < 0.12:
            home.call("pose", "PrimeSlam", 0)
        elif time < 0.26:
            var progress := (time - 0.12) / 0.14
            home.position = Vector2(65 * progress * facing, -125 * progress)
            home.call("pose", "PrimeJump", int(progress * 3.0))
            home.get("body").modulate.a = 1.0 - smoothstep(0.16, 0.26, time)
        elif time < 0.92:
            home.get("body").visible = false
        elif time < 1.08:
            home.call("pose", "PrimeTeleport", 4 - int((time - 0.92) / 0.16 * 5.0))
            home.get("body").modulate.a = smoothstep(0.92, 1.00, time)

func sample_target(entry: Dictionary, time: float) -> void:
    if kind == 0:
        var effect: Node2D = entry["effect"]
        effect.position = entry["center"]
        effect.set("show_impact", bool(entry["committed"]))
        effect.call("sample", time)
        return
    var ghost: Node2D = entry["ghost"]
    ghost.call("idle_at", maxf(time, 0.0))
    ghost.visible = false
    var at: Vector2 = entry["foot"]
    var direction := -1.0 if at.x < 0.0 else 1.0
    ghost.scale = Vector2(direction * 0.20, 0.20)
    var tail := time - first_hit()
    var actual: bool = entry["committed"]
    if kind == 1:
        teleport_ghost(ghost, at, time, direction)
    else:
        jumping_ghost(ghost, at, time, direction)
    var color := Color.WHITE if actual and tail >= 0.0 and tail < 0.15 else GHOST_COLOR
    # A single target has one solid body; groups/random attacks use echoes.
    if entries.size() == 1 and not broad_cast and tail < 0.0:
        color = Color.WHITE
    var disappear := 1.0 - smoothstep(0.0, 0.18, tail) if not actual and tail >= 0.0 else 1.0
    var sprite: Sprite2D = ghost.get("body")
    BODY_STYLE.set_ground(sprite, self, at.y)
    sprite.modulate = Color(color.r, color.g, color.b, color.a * sprite.modulate.a * disappear)
    var flash: Sprite2D = entry["flash"]
    flash.visible = actual and tail >= 0.0 and tail < 0.18
    if flash.visible:
        flash.texture = flash_textures[mini(int(tail / 0.045), 3)]
        flash.region_rect = ASSETS.regions[flash.texture]
        flash.position = entry["center"] if kind == 1 else at + Vector2(0, -24)
        flash.rotation = -0.30 if kind == 1 else 0.40
        flash.scale = Vector2.ONE * (64.0 / maxf(flash.region_rect.size.x, 1.0))
        flash.modulate = Color(0.94, 0.98, 1.0, 0.95 * (1.0 - tail / 0.18))

func teleport_ghost(ghost: Node2D, at: Vector2, time: float, direction: float) -> void:
    if time < 0.26 or time >= 1.05:
        return
    ghost.visible = true
    ghost.position = at + Vector2(-72 * direction, 0)
    if time < 0.42:
        ghost.call("pose", "PrimeTeleport", 4 - int((time - 0.26) / 0.16 * 5.0))
        ghost.get("body").modulate.a = smoothstep(0.26, 0.34, time)
    elif time < 0.90:
        ghost.call("slash_at", time - 0.42)
    else:
        ghost.call("pose", "PrimeTeleport", int((time - 0.90) / 0.15 * 5.0))
        ghost.get("body").modulate.a = 1.0 - smoothstep(0.98, 1.05, time)

func jumping_ghost(ghost: Node2D, at: Vector2, time: float, direction: float) -> void:
    if time < 0.16 or time >= 0.92:
        return
    ghost.visible = true
    var apex := at + Vector2(-85 * direction, -200)
    var landing := at + Vector2(-45 * direction, 0)
    if time < 0.34:
        var progress := clampf((time - 0.12) / 0.22, 0.0, 1.0)
        ghost.position = Vector2.ZERO.lerp(apex, sin(progress * PI * 0.5))
        ghost.call("pose", "PrimeJump", int(progress * 3.0))
        ghost.get("body").modulate.a = smoothstep(0.16, 0.28, time)
    elif time < 0.43:
        ghost.position = apex
        ghost.call("pose", "PrimeJump", 2)
    elif time < 0.58:
        var progress := (time - 0.43) / 0.15
        ghost.position = apex.lerp(landing, pow(progress, 1.55))
        ghost.call("pose", "PrimeSlam", 2 + int(progress * 6.0))
        align_slam(ghost, smoothstep(0.48, 0.58, time))
    else:
        ghost.position = landing
        ghost.call("pose", "PrimeSlam", 7 + int(clampf((time - 0.58) / 0.21, 0.0, 1.0) * 3.0))
        align_slam(ghost, 1.0)
        ghost.get("body").modulate.a = 1.0 - smoothstep(0.73, 0.92, time)

func align_slam(ghost: Node2D, weight: float) -> void:
    var sprite: Sprite2D = ghost.get("body")
    sprite.position.y -= float(slam_offsets.get(sprite.texture, 0.0)) * weight

func _draw() -> void:
    if kind == 0:
        return
    if clock >= 0.18 and clock < (1.12 if kind == 1 else 0.92):
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.28))
        draw_arc(Vector2.ZERO, 22, 0, TAU, 40, Color(0.52, 0.67, 0.9, 0.23), 1.0, true)
        draw_set_transform(Vector2.ZERO)
    for entry in entries.values():
        if not entry["committed"]:
            continue
        var time: float = entry["time"]
        var tail := time - first_hit()
        var at: Vector2 = entry["foot"]
        if kind == 2 and tail >= 0.0 and tail < 0.27:
            var progress := smoothstep(0.0, 0.27, tail)
            draw_set_transform(at, 0.0, Vector2(1.0, 0.23))
            draw_arc(Vector2.ZERO, lerpf(10, 82, progress), 0, TAU, 48, Color(0.92, 0.97, 1.0, (1.0 - progress) * 0.72), 2.0, true)
            draw_set_transform(Vector2.ZERO)
        var start_time := 0.92 if kind == 1 else 0.75
        if time >= start_time and time < start_time + 0.30:
            var progress := (time - start_time) / 0.30
            for mote in range(3):
                var from := at + Vector2(-38 + mote * 10, -45 - mote * 13)
                var point := from.lerp(Vector2(0, -45), smoothstep(0.0, 1.0, progress))
                point.y -= sin(progress * PI) * 30
                draw_circle(point, 1.7, Color(0.70, 0.84, 1.0, sin(progress * PI) * 0.30))

func _process(delta: float) -> void:
    age += delta
    if age > 3.0:
        cancel()
        return
    if started:
        elapsed += delta * playback_speed
        update_visuals()

func _exit_tree() -> void:
    release_body(false)
