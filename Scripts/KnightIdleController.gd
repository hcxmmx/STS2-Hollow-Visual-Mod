extends Node

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")

const SHADOW = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ShadowDashEffect.gd")
const LIFECYCLE = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/KnightLifecycleCast.gd")
const ATTACK_CAST = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/KnightAttackCast.gd")
const SPECIAL_ACTIONS := ["Dark_Descent", "Cast_Level", "Up_Slash"]
var action_revision := 0
var current_action := ""
var world_foot := Vector2.ZERO
var pending_attack_cast: Node
var active_attack_casts: Array[Node] = []
var special_owner: Node
var shadow: Node2D
var lifecycle: Node2D
var lifecycle_state := ""
var lifecycle_clock := 0.0
var player: AnimationPlayer
var low_health := false
var dead := false
var relaxed := false
var managed_action := false
var body: AnimatedSprite2D
var effect_defaults: Array[Dictionary] = []
const EFFECT_PATHS := ["Charge_Slash/Charge_Slash", "Cyclone_Slash/Cyclone_Slash", "Dashv/Dashv", "Dash_Slash/Dash_Slash", "Scream/Scream", "Charge/Charge"]

func _ready() -> void:
    player = get_parent().get_node("AnimationPlayer")
    body = get_parent().get_node("Marker_Knight/Knight_Body")
    for path in EFFECT_PATHS:
        var sprite: AnimatedSprite2D = get_parent().get_node(path)
        effect_defaults.append({"sprite": sprite, "transform": sprite.transform,
            "modulate": sprite.modulate, "self_modulate": sprite.self_modulate,
            "flip_h": sprite.flip_h, "flip_v": sprite.flip_v, "animation": sprite.animation})
    shadow = SHADOW.new()
    shadow.name = "ShadowDashTrail"
    var marker: Node2D = get_parent().get_node("Marker_Knight")
    marker.add_child(shadow)
    marker.move_child(shadow, 0)
    shadow.scale = Vector2.ONE / 1.3
    var idle: Texture2D = body.sprite_frames.get_frame_texture("Idle", 0)
    var area := ASSETS.region(idle)
    var foot := Vector2(area.get_center().x, area.end.y) - idle.get_size() * 0.5
    foot.x = -foot.x
    world_foot = marker.position + foot
    shadow.position = foot
    lifecycle = LIFECYCLE.new()
    lifecycle.name = "KnightDeathRevive"
    marker.add_child(lifecycle)
    lifecycle.position = foot
    player.animation_finished.connect(_on_finished)

func idle_name() -> String:
    return "Idle_Low" if low_health else "Idle"

func set_low_health(value: bool) -> void:
    if low_health == value:
        return
    low_health = value
    request_idle()

func request_idle() -> void:
    if dead or relaxed or lifecycle_state == "revive" or is_instance_valid(special_owner):
        return
    if player.current_animation in ["Idle", "Idle_Low"] or not player.is_playing():
        player.clear_queue()
        player.play(idle_name())
    elif managed_action:
        # HP changes during an action only replace the queued idle.
        player.clear_queue()
        player.queue(idle_name())

func play_action(action: String) -> void:
    if action == "Revive":
        play_revive()
        return
    if dead or (not player.has_animation(action) and action not in SPECIAL_ACTIONS):
        return
    action_revision += 1
    current_action = action
    var prepared: Node
    if action in SPECIAL_ACTIONS and is_instance_valid(pending_attack_cast) and not pending_attack_cast.is_queued_for_deletion() and pending_attack_cast.call("action_name") == action:
        prepared = pending_attack_cast
        pending_attack_cast = null
    cancel_attack_casts()
    # A real new action can interrupt revival; old idle/HP signals cannot.
    lifecycle_state = ""
    lifecycle_clock = 0.0
    lifecycle.call("clear")
    managed_action = true
    dead = action == "Death"
    relaxed = action == "Idle_Map"
    # Low idle's alignment offset must not leak into an attack or skill.
    player.clear_queue()
    player.stop(true)
    player.speed_scale = 1.0
    clean_effects()
    body.stop()
    body.visible = true
    body.modulate = Color.WHITE
    body.self_modulate = Color.WHITE
    body.position = Vector2.ZERO
    player.play(idle_name() if action in SPECIAL_ACTIONS else action)
    # Apply the new clip's first keys immediately, including alignment and facing.
    player.advance(0.0)
    if action in SPECIAL_ACTIONS:
        player.pause()
        if not is_instance_valid(prepared):
            prepared = ATTACK_CAST.new()
            prepared.set("kind", ["Dark_Descent", "Cast_Level", "Up_Slash"].find(action))
            prepared.set("controller", self)
            prepared.set("free_running", true)
            get_parent().add_child(prepared)
        track_attack_cast(prepared)
    elif dead:
        lifecycle_state = "death"
        lifecycle.call("sample", "death", 0.0)
        body.visible = false
    elif not relaxed:
        player.queue(idle_name())

func play_revive() -> void:
    # StartReviveAnim and the native Revive trigger can both notify us.
    if not dead or lifecycle_state == "revive":
        return
    action_revision += 1
    current_action = "Revive"
    cancel_attack_casts()
    dead = false
    relaxed = false
    managed_action = true
    player.clear_queue()
    player.stop(true)
    player.speed_scale = 1.0
    clean_effects()
    body.stop()
    body.visible = false
    body.modulate = Color.WHITE
    body.self_modulate = Color.WHITE
    body.position = Vector2.ZERO
    lifecycle_state = "revive"
    lifecycle_clock = 0.0
    lifecycle.call("sample", "revive", 0.0)

func finish_revive() -> void:
    lifecycle_state = ""
    lifecycle_clock = 0.0
    lifecycle.call("clear")
    body.visible = true
    body.modulate = Color.WHITE
    body.self_modulate = Color.WHITE
    body.position = Vector2.ZERO
    player.clear_queue()
    player.speed_scale = 1.0
    player.play(idle_name())
    player.advance(0.0)

func clean_effects() -> void:
    if is_instance_valid(shadow):
        shadow.call("sample", -1.0)
    for state in effect_defaults:
        var sprite: AnimatedSprite2D = state["sprite"]
        sprite.stop()
        sprite.visible = false
        sprite.transform = state["transform"]
        sprite.modulate = state["modulate"]
        sprite.self_modulate = state["self_modulate"]
        sprite.flip_h = state["flip_h"]
        sprite.flip_v = state["flip_v"]
        sprite.animation = state["animation"]
        sprite.frame = 0
    get_parent().get_node("Prime2").visible = false

func _on_finished(_animation: StringName) -> void:
    if managed_action and not dead and not relaxed and lifecycle_state == "" and not is_instance_valid(special_owner):
        player.clear_queue()
        player.play(idle_name())

func _process(delta: float) -> void:
    if is_instance_valid(special_owner):
        body.visible = false
    if lifecycle_state != "":
        lifecycle_clock += delta
        lifecycle.call("sample", lifecycle_state, lifecycle_clock)
        body.visible = false
        if lifecycle_state == "revive" and lifecycle_clock >= 0.62:
            finish_revive()
    if is_instance_valid(shadow):
        shadow.call("sample", player.current_animation_position if player.current_animation == "Shadow_Dash" and not dead and lifecycle_state == "" and not is_instance_valid(special_owner) else -1.0)

func can_play_attack() -> bool:
    return not dead and not relaxed

func prepare_attack_cast(cast: Node) -> void:
    if is_instance_valid(pending_attack_cast):
        pending_attack_cast.call("cancel")
    pending_attack_cast = cast

func track_attack_cast(cast: Node) -> void:
    if pending_attack_cast == cast:
        pending_attack_cast = null
    active_attack_casts = active_attack_casts.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
    if not active_attack_casts.has(cast):
        active_attack_casts.append(cast)
    cast.call("start")

func cancel_attack_casts() -> void:
    if is_instance_valid(pending_attack_cast):
        pending_attack_cast.call("cancel")
    pending_attack_cast = null
    for cast in active_attack_casts:
        if is_instance_valid(cast) and not cast.is_queued_for_deletion():
            cast.call("cancel")
    active_attack_casts.clear()

func claim_special(cast: Node) -> void:
    if is_instance_valid(special_owner) and special_owner != cast:
        special_owner.call("cancel")
    special_owner = cast
    player.clear_queue()
    player.pause()
    body.visible = false

func release_special(cast: Node, revision: int, _finished: bool) -> void:
    if special_owner != cast:
        return
    special_owner = null
    if not is_inside_tree() or dead or lifecycle_state != "":
        return
    body.visible = true
    body.modulate = Color.WHITE
    body.self_modulate = Color.WHITE
    body.position = Vector2.ZERO
    if revision == action_revision:
        player.clear_queue()
        player.speed_scale = 1.0
        player.play(idle_name())
        player.advance(0.0)

func _exit_tree() -> void:
    cancel_attack_casts()
