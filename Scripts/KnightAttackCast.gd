extends Node2D

const ACTOR = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/KnightAttackActor.gd")
const EFFECT = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/KnightAttackEffect.gd")
@export var kind := 0 # Dark descent / shadow soul / stationary upward slash.
var controller: Node
var revision := -1
var broad_cast := false
var free_running := false
var playback_speed := 1.0
var canceled := false
var started := false
var elapsed := 0.0
var age := 0.0
var clock := -1.0
var home: Node2D
var home_effect: Node2D
var entries: Dictionary = {}
var target_feet: Dictionary = {}
var target_contacts: Dictionary = {}

func action_name() -> String:
    return ["Dark_Descent", "Cast_Level", "Up_Slash"][kind]

func first_hit() -> float:
    return [0.88, 0.60, 0.09][kind]

func duration() -> float:
    return [1.12, 0.90, 0.44][kind]

func _ready() -> void:
    home = ACTOR.new()
    home.scale = Vector2.ONE * 1.3
    add_child(home)
    home_effect = EFFECT.new()
    home_effect.set("caster", Vector2.ZERO)
    home_effect.set("show_travel", false)
    add_child(home_effect)
    home.visible = false
    if is_instance_valid(controller):
        var root: Node2D = controller.get_parent()
        # Preserve the complete basis; negative X decomposes into rotation +
        # negative Y in Godot, so copying only global_scale flips the wrong axis.
        var transform := root.global_transform
        transform.x /= 1.3
        transform.y /= 1.3
        transform.origin = root.to_global(controller.get("world_foot"))
        global_transform = transform

func bind_target_foot(key: int, at: Vector2) -> void:
    target_feet[key] = at

func bind_target_contact(key: int, at: Vector2) -> void:
    target_contacts[key] = at

func add_target(key: int, center: Vector2, _caster: Vector2, _size: float) -> void:
    if entries.has(key):
        return
    var effect := EFFECT.new()
    effect.set("caster", Vector2.ZERO)
    effect.set("show_home", false)
    add_child(effect)
    entries[key] = {"effect": effect, "committed": false,
        "center": to_local(center), "foot": to_local(target_feet.get(key, center + Vector2(0, 70))),
        "contact": to_local(target_contacts.get(key, center)), "time": -1.0}
    if started:
        update_visuals()

func commit_target(key: int, center: Vector2, caster: Vector2, size: float) -> void:
    add_target(key, center, caster, size)
    var entry: Dictionary = entries[key]
    entry["center"] = to_local(center)
    entry["foot"] = to_local(target_feet.get(key, center + Vector2(0, 70)))
    entry["contact"] = to_local(target_contacts.get(key, center))
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
    # Hit callbacks only select impacts; never skip the jump/cast wind-up.
    clock = elapsed
    home.visible = true
    home.position = Vector2.ZERO
    home.call("idle_at", maxf(clock, 0.0))
    sample_home(clock)
    home_effect.call("sample", kind, clock)
    if kind == 2:
        home_effect.call("align_up_slash", home.get("body"), home.get("pose_frame"))
    var done := clock >= duration()
    for entry in entries.values():
        var time: float = clock
        entry["time"] = time
        var effect: Node2D = entry["effect"]
        effect.set("target_center", entry["center"])
        effect.set("target_foot", entry["foot"])
        effect.set("target_contact", entry["contact"])
        effect.set("show_impact", bool(entry["committed"]))
        effect.call("sample", kind, time)
        if time < duration():
            done = false
    if done:
        visible = false
        release_body(true)
        queue_free()

func sample_home(time: float) -> void:
    if kind == 1:
        if time >= 0.0 and time < 0.78:
            home.call("pose", "Cast", mini(int(time / 0.70 * 8.0), 8))
        return
    if kind == 2:
        if time >= 0.0 and time < 0.44:
            var keys := [0.0, 0.06, 0.12, 0.21, 0.33]
            var frame := 0
            for index in range(keys.size()):
                if time >= keys[index]:
                    frame = index
            home.call("pose", "Up", frame, true)
        return
    if time < 0.0 or time >= 1.03:
        return
    if time < 0.10:
        home.call("pose", "Quake", 0, true)
    elif time < 0.30:
        var progress := (time - 0.10) / 0.20
        home.position.y -= sin(progress * PI * 0.5) * 175.0
        home.call("pose", "Jump", mini(int(progress * 5.0), 5))
    elif time < 0.43:
        home.position.y -= 175.0
        home.call("pose", "DarkQuake", mini(int((time - 0.30) / 0.13 * 3.0), 3))
    elif time < 0.60:
        var progress := (time - 0.43) / 0.17
        home.position.y -= (1.0 - pow(progress, 1.5)) * 175.0
        home.call("pose", "DarkQuake", 3 + mini(int(progress * 5.0), 5), true)
    else:
        home.call("pose", "DarkQuake", 8 + mini(int((time - 0.60) / 0.40 * 10.0), 10), true)

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
