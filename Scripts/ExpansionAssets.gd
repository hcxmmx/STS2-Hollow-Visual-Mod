extends RefCounted

const DATA = preload("res://Hcxmmx_Hollow_Knight_Skin/Scripts/BakedAnimationAssets.gd")
static var textures: Dictionary = {}
static var regions: Dictionary = {}
static var unions: Dictionary = DATA.UNIONS

static func frames(clip: String) -> Array:
    if not textures.has(clip):
        var result: Array = DATA.TEXTURES[clip]
        for texture in result:
            regions[texture] = DATA.REGIONS[texture.resource_path]
        textures[clip] = result
    return textures[clip]

static func region(texture: Texture2D) -> Rect2:
    if not regions.has(texture):
        # All runtime textures are listed in the baked table; never read the GPU.
        regions[texture] = DATA.REGIONS[texture.resource_path]
    return regions[texture]
