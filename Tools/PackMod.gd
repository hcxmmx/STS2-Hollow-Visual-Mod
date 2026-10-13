extends SceneTree

var packer := PCKPacker.new()
var count := 0
var failed := false
var imported_files: Dictionary = {}

func _initialize() -> void:
    var output := "res://../Build/Hcxmmx_Hollow_Knight_Skin/Hcxmmx_Hollow_Knight_Skin.pck"
    if packer.pck_start(ProjectSettings.globalize_path(output)) != OK:
        quit(1)
        return
    # Only ship runtime resources. Workshop tools, old packages and repository
    # documents may live next to these folders but do not belong in the mod PCK.
    for folder in ["Animations", "Assets", "Audio", "Scenes", "Scripts"]:
        add_folder("res://Hcxmmx_Hollow_Knight_Skin/" + folder)
    # Texture .import files refer to these generated resources. C# ships as a
    # separate DLL, so no .NET executable/solution is required for this asset pack.
    for source in imported_files:
        if packer.add_file(source, ProjectSettings.globalize_path(source)) != OK:
            failed = true
            push_error("Cannot pack imported resource " + source)
        count += 1
    var result := packer.flush()
    print("PACK_MOD files=", count, " result=", result)
    quit(1 if failed or result != OK else 0)

func add_folder(path: String) -> void:
    var folder := DirAccess.open(path)
    if folder == null:
        failed = true
        return
    for entry in folder.get_directories():
        if not entry.begins_with("."):
            add_folder(path.path_join(entry))
    for entry in folder.get_files():
        if entry.begins_with(".") or entry.ends_with(".cs") or entry.ends_with(".uid") or entry.ends_with(".md5"):
            continue
        var source := path.path_join(entry)
        if entry.ends_with(".import"):
            var config := ConfigFile.new()
            if config.load(source) == OK:
                for dependency in config.get_value("deps", "dest_files", []):
                    imported_files[dependency] = true
        var disk_source := ProjectSettings.globalize_path(source)
        if entry.ends_with(".tscn"):
            # A mod's editor UIDs are absent from the host game's UID database.
            # Explicit paths are stable; strip editor-only UID hints in the pack.
            var matcher := RegEx.new()
            matcher.compile(' uid="[^"]*"')
            var content := matcher.sub(FileAccess.get_file_as_string(source), "", true)
            disk_source = ProjectSettings.globalize_path("res://../Build/PackSources/" + entry)
            DirAccess.make_dir_recursive_absolute(disk_source.get_base_dir())
            var file := FileAccess.open(disk_source, FileAccess.WRITE)
            file.store_string(content)
            file.close()
        var result := packer.add_file(source, disk_source)
        if result != OK:
            failed = true
            push_error("Cannot pack " + source)
        count += 1
