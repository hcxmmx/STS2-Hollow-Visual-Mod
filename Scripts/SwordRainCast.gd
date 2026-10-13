extends Node2D

const EFFECT = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/SwordRainEffect.gd")
const ARC = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/ArcSlashEffect.gd")
@export var pattern := 0
@export var effect_kind := 0
var broad_cast := false
var canceled := false
var playback_speed := 1.0
var body_speed := 1.0
var started := false
var elapsed := 0.0
var age := 0.0
var entries: Dictionary = {}

func first_hit() -> float:
    # Cross the computed launch + flight boundary despite floating-point rounding.
    if effect_kind == 1:
        return 0.4401 if pattern == 0 else 0.4901
    return 0.5201 if pattern == 0 else 0.5901

func duration() -> float:
    return ARC.DURATION if effect_kind == 1 else EFFECT.DURATION

func cancel() -> void:
    canceled = true
    visible = false
    queue_free()

func add_target(key: int, target_center: Vector2, caster_foot: Vector2, size: float) -> void:
    if entries.has(key):
        return
    var effect := (ARC.new() if effect_kind == 1 else EFFECT.new()) as Node2D
    effect.set("pattern", pattern)
    effect.set("show_impact", false)
    effect.set("caster_offset", (caster_foot - target_center) / size)
    add_child(effect)
    effect.global_position = target_center
    effect.global_scale = Vector2.ONE * size
    entries[key] = {"effect": effect, "committed": false, "start_clock": elapsed if started else 0.0}

func start() -> void:
    started = true
    elapsed = 0.0
    update_effects()

func commit_target(key: int, target_center: Vector2, caster_foot: Vector2, size: float) -> void:
    if entries.has(key) and entries[key]["committed"]:
        # A command that plays its attacker animation only once may hit again.
        # Replace that target's finished volley without leaving duplicate nodes.
        entries[key]["effect"].visible = false
        entries[key]["effect"].queue_free()
        entries.erase(key)
    add_target(key, target_center, caster_foot, size)
    entries[key]["effect"].global_position = target_center
    entries[key]["effect"].set("show_impact", true)
    entries[key]["committed"] = true
    if not started:
        started = true
    update_effects()

func update_effects() -> void:
    var finished := elapsed >= duration()
    for key in entries:
        var entry: Dictionary = entries[key]
        # A hit can enable its flash, but cannot teleport an in-flight sword.
        var time: float = elapsed - float(entry["start_clock"])
        entry["effect"].call("sample", time)
        if time < duration():
            finished = false
    if finished:
        queue_free()

func _process(delta: float) -> void:
    age += delta
    if age > 3.0:
        cancel()
        return
    if not started:
        return
    elapsed += delta * playback_speed
    update_effects()
    # Covers canceled commands, invalid targets and interruptions before a hit.
