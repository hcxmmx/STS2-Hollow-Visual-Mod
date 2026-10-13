extends SceneTree

# Build-time only. Read raw PNGs on the CPU; gameplay never downloads textures
# from the GPU or scans millions of transparent pixels to find their bounds.
const ROOT := "res://Hcxmmx_Hollow_Knight_Skin/"

func _initialize() -> void:
    var clips: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "Assets/ExpansionAssets/frames.json"))
    add_sequence(clips, "ArcWave", "ArcSlashAssets/Knight_charge_slash_effect/Knight_charge_slash_effect", 1, 8)
    add_sequence(clips, "SwordShot", "SwordRainAssets/HK Prime Cln_HK_Prime_Dart_Shot/HK Prime Cln_HK_Prime_Dart_Shot", 0, 4)
    add_sequence(clips, "SwordAntic", "SwordRainAssets/HK Prime Cln_HK_Prime_Dart_Antic/HK Prime Cln_HK_Prime_Dart_Antic", 0, 3)
    add_sequence(clips, "PrimeDeath", "SeniorLifecycle/HK Prime Cln_death/HK Prime Cln_death", 0, 6)
    add_sequence(clips, "KnightDeath", "Knight_Body/Knight_death_anim/Knight_death_anim", 0, 14)
    add_sequence(clips, "KnightShade", "KnightLifecycle/Hollow Shade Cln_idle/Hollow Shade Cln_idle", 0, 12)
    add_sequence(clips, "KnightVoidBurst", "KnightLifecycle/Hollow Shade Cln_death_explode/Hollow Shade Cln_death_explode", 0, 3)
    add_sequence(clips, "KnightWake", "KnightLifecycle/Knight_wake/Knight_wake", 0, 5)
    clips["KnightQuake"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0005.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0006.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0007.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0008.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0009.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0010.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0011.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0012.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0013.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake/Knight_quake0014.png"]
    clips["KnightDarkQuake"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0002.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0004.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0005.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0006.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0007.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0008.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0009.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0010.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0011.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0012.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0013.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0014.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0015.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0016.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0017.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_quake_cast_level_02_shadow/Knight_quake_cast_level_02_shadow0018.png"]
    clips["KnightJump"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_01.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_02.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_03.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_04.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_05.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_jump/Knight_jump_06.png"]
    clips["KnightUp"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash/Knight_up_slash0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash/Knight_up_slash0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash/Knight_up_slash0002.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash/Knight_up_slash0003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash/Knight_up_slash0004.png"]
    clips["KnightUpEffect"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash_effect/Knight_up_slash_effect0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash_effect/Knight_up_slash_effect0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Knight_up_slash_effect/Knight_up_slash_effect0002.png"]
    clips["KnightSoul"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0002.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0004.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0005.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0006.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0007.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0008.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_Black_spell/Hollow Shade Cln_Black_spell0009.png"]
    clips["KnightPortal"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0002.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0004.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0005.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0006.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0007.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/KnightAttackAssets/Hollow Shade Cln_black_spell_portal/Hollow Shade Cln_black_spell_portal0008.png"]
    clips["KnightSoulCast"] = ["res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020000.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020001.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020002.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020003.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020004.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020005.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020006.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020007.png", "res://Hcxmmx_Hollow_Knight_Skin/Assets/Knight_Body/Knight_cast_level/Knight_cast_level_020008.png"]
    var rectangles: Dictionary = {}
    var unions: Dictionary = {}
    for clip in clips:
        var union := Rect2i()
        for path in clips[clip]:
            if not rectangles.has(path):
                var image := Image.load_from_file(ProjectSettings.globalize_path(path))
                if image == null or image.is_empty():
                    push_error("Cannot bake animation texture: " + str(path))
                    quit(1)
                    return
                rectangles[path] = image.get_used_rect()
            var area: Rect2i = rectangles[path]
            if area.has_area():
                union = union.merge(area) if union.has_area() else area
        unions[clip] = union
    var content := "extends RefCounted\n\n# Generated by BakeAnimationAssets.gd. Rebuild after changing source PNGs.\n"
    content += "# Preloads are resolved when the mod's scenes load, before attack callbacks.\nconst TEXTURES := {\n"
    for clip in clips:
        content += "    " + JSON.stringify(clip) + ": [\n"
        for path in clips[clip]:
            content += "        preload(" + JSON.stringify(path) + "),\n"
        content += "    ],\n"
    content += "}\n\nconst REGIONS := {\n"
    for path in rectangles:
        content += "    " + JSON.stringify(path) + ": " + rect_code(rectangles[path]) + ",\n"
    content += "}\n\nconst UNIONS := {\n"
    for clip in unions:
        content += "    " + JSON.stringify(clip) + ": " + rect_code(unions[clip]) + ",\n"
    content += "}\n"
    var destination := FileAccess.open(ROOT + "Scripts/BakedAnimationAssets.gd", FileAccess.WRITE)
    if destination == null:
        push_error("Cannot write baked animation metadata")
        quit(1)
        return
    destination.store_string(content)
    destination.close()
    print("BAKE_ANIMATION_ASSETS frames=", rectangles.size(), " clips=", clips.size())
    quit(0)

func add_sequence(clips: Dictionary, name: String, prefix: String, first: int, count: int) -> void:
    var paths: Array[String] = []
    for index in range(first, first + count):
        paths.append(ROOT + "Assets/" + prefix + "%04d.png" % index)
    clips[name] = paths

func rect_code(area: Rect2i) -> String:
    return "Rect2(%d, %d, %d, %d)" % [area.position.x, area.position.y, area.size.x, area.size.y]
