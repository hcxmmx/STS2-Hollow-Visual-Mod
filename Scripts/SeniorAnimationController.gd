extends Node2D

const ASSETS = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ExpansionAssets.gd")

const FALL_TIME := 0.45
const REVIVE_TIME := 1.05

var vessel: Node2D
var body: AnimatedSprite2D
var player: AnimationPlayer
var overlay: Sprite2D
var death_frames: Array[Texture2D] = []
var teleport_frames: Array[Texture2D] = []
var footprints: Dictionary = {}
var foot := Vector2.ZERO
var world_foot := Vector2.ZERO
var mode := "alive"
var clock := 0.0
var live := false
var action_revision := 0
var current_action := ""
var focus_root: Node2D
var focus_ring: Sprite2D
var focus_rune: Sprite2D
var focus_glow: Sprite2D
var ring_frames: Array[Texture2D] = []

func _ready() -> void:
    vessel = get_parent() as Node2D
    body = vessel.get_node("Marker_Prime/Prime_Body")
    player = vessel.get_node("AnimationPlayer")
    player.animation_finished.connect(_on_action_finished)
    # Queued transitions emit animation_started/changed instead of finished.
    player.animation_started.connect(_on_animation_started)
    var texture := body.sprite_frames.get_frame_texture("Idle", 0)
    foot = _texture_foot(texture)
    world_foot = Vector2(300, -265) + foot
    for i in range(6):
        death_frames.append(load("res://Hcxmmx_Hollow_Knight_Skin/Assets/SeniorLifecycle/HK Prime Cln_death/HK Prime Cln_death%04d.png" % i))
    for i in range(5):
        teleport_frames.append(load("res://Hcxmmx_Hollow_Knight_Skin/Assets/SeniorLifecycle/HK Prime Cln_teleport/HK Prime Cln_teleport%04d.png" % i))
    overlay = Sprite2D.new()
    vessel.get_node("Marker_Prime").add_child(overlay)
    overlay.visible = false
    _build_focus(texture)
    focus_root.visible = false

func _build_focus(reference: Texture2D) -> void:
    var asset_path := "res://Hcxmmx_Hollow_Knight_Skin/Assets/SeniorLifecycle/HK Prime Cln_focus_ring/"
    for i in range(4):
        ring_frames.append(load(asset_path + "HK Prime Cln_focus_ring%04d.png" % i))
    focus_root = Node2D.new()
    var body_height := float(ASSETS.region(reference).size.y)
    focus_root.position = foot + Vector2(0, -body_height * 0.52)
    # Same relative layer as the body; sibling order puts it behind the vessel
    # without sending it behind the combat background via a negative Z index.
    var marker := vessel.get_node("Marker_Prime") as Node2D
    marker.add_child(focus_root)
    marker.move_child(focus_root, 0)
    # Partial arcs share the complete ring's crop, so their center never shifts.
    var ring_bounds := ASSETS.region(ring_frames[3])
    focus_ring = Sprite2D.new()
    focus_ring.region_enabled = true
    focus_ring.region_rect = ring_bounds
    focus_ring.scale = Vector2.ONE * (body_height * 1.22 / ring_bounds.size.y)
    focus_root.add_child(focus_ring)
    focus_rune = _focus_sprite(load(asset_path + "HK Prime Cln_focus_rune.png"), body_height * 1.08)
    focus_glow = _focus_sprite(load(asset_path + "HK Prime Cln_focus_ring.png"), body_height * 1.32)

func _focus_sprite(texture: Texture2D, diameter: float) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.texture = texture
    sprite.region_enabled = true
    sprite.region_rect = ASSETS.region(texture)
    sprite.scale = Vector2.ONE * (diameter / sprite.region_rect.size.y)
    focus_root.add_child(sprite)
    return sprite

func _update_focus() -> void:
    focus_root.visible = mode == "revive" and clock < 0.68
    if not focus_root.visible:
        return
    var envelope := smoothstep(0.0, 0.09, clock) * (1.0 - smoothstep(0.32, 0.68, clock))
    var formation := smoothstep(0.0, 0.22, clock)
    focus_root.scale = Vector2.ONE * lerpf(0.88, 1.04, formation)
    focus_ring.texture = ring_frames[mini(int(clock / 0.06), 3)]
    focus_ring.modulate = Color(0.90, 0.96, 1.0, envelope * 0.68)
    focus_rune.modulate = Color(0.90, 0.96, 1.0, envelope * smoothstep(0.02, 0.16, clock) * 0.48)
    var flash := smoothstep(0.20, 0.28, clock) * (1.0 - smoothstep(0.28, 0.50, clock))
    focus_glow.modulate = Color(0.90, 0.96, 1.0, flash * 0.22)

func _texture_foot(texture: Texture2D) -> Vector2:
    if footprints.has(texture):
        return footprints[texture]
    var bounds := ASSETS.region(texture)
    var anchor := Vector2.INF
    if bounds.has_area():
        anchor = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y) - texture.get_size() * 0.5
    footprints[texture] = anchor
    return anchor

func _set_overlay(texture: Texture2D, color: Color, lift: float = 0.0) -> void:
    overlay.texture = texture
    var anchor := _texture_foot(texture)
    if anchor == Vector2.INF:
        overlay.visible = false
        return
    overlay.position = foot - anchor + Vector2(0, lift)
    overlay.modulate = color
    overlay.visible = true

func _base_animation(animation: String, time: float) -> void:
    if player.current_animation != animation:
        player.play(animation)
        player.pause()
    var length := player.get_animation(animation).length
    player.seek(fmod(time, length) if animation == "Idle" else minf(time, length), true)

func sample(state: String, time: float) -> void:
    mode = state
    clock = maxf(time, 0.0)
    body.modulate = Color.WHITE
    match mode:
        "defeat":
            body.visible = false
            var index := mini(int(clock / 0.075), 5)
            var fade := smoothstep(0.18, FALL_TIME, clock)
            var color := Color.WHITE.lerp(Color(0.52, 0.58, 0.75, 0.38), fade)
            var lift := -2.0 * sin(clock * 2.2) if clock > FALL_TIME else 0.0
            _set_overlay(death_frames[index], color, lift)
        "revive":
            if clock < 0.275:
                body.visible = false
                var index := clampi(4 - int(clock / 0.055), 0, 4)
                _set_overlay(teleport_frames[index], Color(0.8, 0.88, 1.0, smoothstep(0.0, 0.20, clock)))
            else:
                overlay.visible = false
                body.visible = true
                var roar_time := (clock - 0.275) * 2.2
                if clock < REVIVE_TIME:
                    _base_animation("Roar", roar_time)
                else:
                    _base_animation("Idle", clock - REVIVE_TIME)
        "alive":
            overlay.visible = false
            body.visible = true
            _base_animation("Idle", clock)
    _update_focus()
    queue_redraw()

func play_defeat() -> void:
    if mode == "defeat":
        return
    action_revision += 1
    current_action = "Death"
    clear_combo()
    _clean_effects()
    player.clear_queue()
    player.stop()
    clock = 0.0
    mode = "defeat"
    live = true
    sample(mode, clock)

func play_revive() -> void:
    if mode == "revive":
        return
    action_revision += 1
    current_action = "Revive"
    clear_combo()
    _clean_effects()
    vessel.modulate = Color.WHITE
    player.clear_queue()
    player.stop()
    clock = 0.0
    mode = "revive"
    live = true
    sample(mode, clock)

func _process(delta: float) -> void:
    if live:
        sample(mode, clock + delta)
        if mode == "revive" and clock >= REVIVE_TIME:
            restore_alive()
            player.play("Idle")

func _draw() -> void:
    if mode == "defeat":
        for i in range(8):
            var progress := fmod(clock * 0.5 + float(i) / 8.0, 1.0)
            var at := world_foot + Vector2(sin(float(i) * 2.4) * 90.0, -progress * 180.0)
            draw_circle(at, 2.5, Color(0.56, 0.64, 0.86, sin(progress * PI) * 0.45))


# Each instantiated vessel owns its combo progress. Ordinary Idle does not break it.
var combo: Array[String] = []
var combo_cursor := 0
const ATTACK_CHOICES := ["Dash", "Slash_1", "Slash_2", "Slash_3", "Shoot", "Down_Slam", "SwordRain_Columns", "SwordRain_Fan", "Slash_Combo", "Focus_Burst", "Teleport_Slash", "Jump_Slam"]
const ATTACK_CLIPS := ["Dash", "Slash_1", "Slash_2", "Slash_3", "Shoot", "Down_Slam", "SwordRain_Columns", "SwordRain_Fan", "Focus_Burst", "Teleport_Slash", "Jump_Slam"]

func clear_combo() -> void:
    combo.clear()
    combo_cursor = 0

func next_attack(roll: int) -> String:
    if combo_cursor < combo.size():
        var action := combo[combo_cursor]
        combo_cursor += 1
        if combo_cursor == combo.size():
            clear_combo()
        return action
    var chosen: String = ATTACK_CHOICES[posmod(roll, ATTACK_CHOICES.size())]
    if chosen == "Slash_Combo":
        combo.assign(["Slash_1", "Slash_2", "Slash_3"])
        combo_cursor = 1
        return combo[0]
    return chosen

func _clean_effects() -> void:
    cancel_sword_casts()
    _hide_attached_effects()

func _hide_attached_effects() -> void:
    for effect in ["Shot", "Tendril"]:
        var sprite := vessel.get_node("Marker_Prime/" + effect) as AnimatedSprite2D
        sprite.stop()
        sprite.visible = false
        sprite.frame = 0

func restore_alive() -> void:
    mode = "alive"
    live = false
    overlay.visible = false
    focus_root.visible = false
    body.visible = true
    body.modulate = Color.WHITE
    body.position = Vector2.ZERO
    vessel.modulate = Color.WHITE
    player.speed_scale = 1.0
    queue_redraw()

func play_action(action: String) -> void:
    if mode != "alive":
        cancel_sword_casts()
        return
    action_revision += 1
    current_action = action
    var prepared: Node = pending_sword_cast if action.begins_with("SwordRain_") or action in ["Slash_1", "Slash_2", "Slash_3", "Focus_Burst", "Teleport_Slash", "Jump_Slam"] else null
    if prepared != null:
        pending_sword_cast = null
    _clean_effects()
    restore_alive()
    player.clear_queue()
    if action in ["Focus_Burst", "Teleport_Slash", "Jump_Slam"]:
        player.play("Idle")
        player.advance(0.0)
    else:
        player.play("Dart_Shoot" if action.begins_with("SwordRain_") else action)
        player.advance(0.0)
        player.queue("Idle")
    if is_instance_valid(prepared) and not prepared.is_queued_for_deletion():
        active_sword_casts.append(prepared)
        apply_cast_body_speed(prepared, action, action_revision)
        prepared.call("start")

func handle_trigger(trigger: String) -> void:
    var normalized := trigger.to_lower()
    if normalized in ["die", "death", "dead"]:
        play_defeat()
        return
    if normalized in ["revive", "spawn", "summon"]:
        play_revive()
        return
    if normalized in ["idle", "idle_loop"]:
        if mode == "alive":
            if is_instance_valid(special_owner) and not special_owner.is_queued_for_deletion():
                return
            _hide_attached_effects()
            player.clear_queue()
            player.speed_scale = 1.0
            player.play("Idle")
            player.advance(0.0)
        return
    # Lifecycle animations finish through their own transition, not combat signals.
    if mode != "alive":
        cancel_sword_casts()
        return
    if normalized in ["hit", "hurt"]:
        clear_combo()
        if mode != "defeat":
            play_action("Counter")
        return
    if trigger in ATTACK_CLIPS:
        play_action(trigger)
        return
    if normalized == "attack":
        play_action(next_attack(randi_range(0, ATTACK_CHOICES.size() - 1)))
        return
    # Unknown non-idle triggers are other action types, so they interrupt a combo.
    clear_combo()
    cancel_sword_casts()
    if mode == "alive" and player.has_animation(trigger):
        play_action(trigger)


var pending_sword_cast: Node
var active_sword_casts: Array[Node] = []

func prepare_sword_cast(cast: Node) -> void:
    if is_instance_valid(pending_sword_cast):
        pending_sword_cast.call("cancel")
    pending_sword_cast = cast

func cancel_sword_casts() -> void:
    if is_instance_valid(pending_sword_cast):
        pending_sword_cast.call("cancel")
    pending_sword_cast = null
    for cast in active_sword_casts:
        if is_instance_valid(cast) and not cast.is_queued_for_deletion():
            cast.call("cancel")
    active_sword_casts.clear()

func track_sword_cast(cast: Node) -> void:
    if pending_sword_cast == cast:
        pending_sword_cast = null
    active_sword_casts = active_sword_casts.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
    active_sword_casts.append(cast)
    cast.call("start")

func _on_action_finished(animation: StringName) -> void:
    if animation in [&"Dart_Shoot", &"Slash_1", &"Slash_2", &"Slash_3"]:
        player.speed_scale = 1.0

func _exit_tree() -> void:
    cancel_sword_casts()

# A visual cast may hide the body, but never moves the Creature or its hitbox.
# Ownership prevents an old cast's exit from undoing a new action/death.
var special_owner: Node

func claim_special(cast: Node) -> void:
    if is_instance_valid(special_owner) and special_owner != cast:
        special_owner.call("cancel")
    special_owner = cast
    player.clear_queue()
    player.stop(true)
    body.visible = false

func release_special(cast: Node, revision: int, finished: bool) -> void:
    if special_owner != cast:
        return
    special_owner = null
    if mode != "alive":
        return
    body.visible = true
    body.modulate = Color.WHITE
    body.position = Vector2.ZERO
    if finished and revision == action_revision:
        player.speed_scale = 1.0
        player.play("Idle")
        player.advance(0.0)

func _on_animation_started(animation: StringName) -> void:
    if animation == &"Idle":
        player.speed_scale = 1.0

func apply_cast_body_speed(cast: Node, action: String, revision: int) -> void:
    # Deferred VFX Ready callbacks may arrive after the body has gone idle,
    # or after another action. Speed belongs only to the matching body clip.
    if mode != "alive" or revision != action_revision or current_action != action:
        return
    if not is_instance_valid(cast) or cast.is_queued_for_deletion():
        return
    var clip := "Dart_Shoot" if action.begins_with("SwordRain_") else action
    if action not in ["Slash_1", "Slash_2", "Slash_3", "SwordRain_Columns", "SwordRain_Fan"]:
        return
    if player.current_animation == clip and player.is_playing():
        player.speed_scale = float(cast.get("body_speed"))
