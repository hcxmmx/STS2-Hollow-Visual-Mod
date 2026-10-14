shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range(0.0, 1.0) = 0.75;
uniform vec2 shape_min = vec2(-100.0, -200.0);
uniform vec2 shape_size = vec2(200.0, 400.0);
uniform bool mirrored = false;
uniform vec2 face_min = vec2(0.0);
uniform vec2 face_size = vec2(1.0);
uniform bool face_valid = false;
uniform vec2 cloth_min = vec2(-100.0, -200.0);
uniform vec2 cloth_size = vec2(200.0, 400.0);
varying vec2 body_point;
varying vec4 body_tint;

void vertex() {
    body_point = VERTEX;
    body_tint = COLOR;
}

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    vec2 point = clamp((body_point - shape_min) / max(shape_size, vec2(1.0)), vec2(0.0), vec2(1.0));
    float luminance = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
    float ink = 1.0 - smoothstep(0.04, 0.22, luminance);
    float cloth = smoothstep(0.18, 0.32, luminance) * (1.0 - smoothstep(0.73, 0.90, luminance));
    // A stable, broad light direction. No frame edits or fabricated moving folds.
    float shade = 1.0 - strength * (0.09 * point.y + 0.04 * point.x);
    vec2 fabric = clamp((body_point - cloth_min) / max(cloth_size, vec2(1.0)), vec2(0.0), vec2(1.0));
    float cloth_shade = 1.0 - strength * (0.045 + 0.24 * fabric.x + 0.12 * fabric.y - 0.085 * sin(fabric.x * 3.14159));
    shade = mix(shade, cloth_shade, cloth);
    vec2 face = (body_point - face_min) / max(face_size, vec2(1.0));
    if (face_valid && luminance > 0.79 && face.x >= 0.0 && face.x <= 1.0 && face.y >= 0.0 && face.y <= 1.0) {
        shade = 1.0 - strength * (0.035 + 0.14 * face.x + 0.06 * face.y + 0.055 * pow(2.0 * face.x - 1.0, 2.0));
    }
    vec3 tint = mix(vec3(1.0), vec3(0.95, 0.98, 0.96), strength);
    vec3 rgb = pixel.rgb * shade * tint;
    // Keep black silhouettes, with just enough lifted ink to read on dark ground.
    rgb += strength * ink * vec3(0.018, 0.028, 0.032);
    vec2 texel = TEXTURE_PIXEL_SIZE * 1.5;
    float left_alpha = texture(TEXTURE, UV + vec2(mirrored ? texel.x : -texel.x, 0.0)).a;
    float top_alpha = texture(TEXTURE, UV - vec2(0.0, texel.y)).a;
    float edge = clamp(max(pixel.a - left_alpha, (pixel.a - top_alpha) * 0.70), 0.0, 1.0);
    // Inward edge reflection: alpha is unchanged, so this never becomes a halo.
    rgb += vec3(0.66, 0.79, 0.77) * edge * strength * mix(0.05, 0.18, ink);
    COLOR = vec4(clamp(rgb, vec3(0.0), vec3(1.0)), pixel.a) * body_tint;
}
