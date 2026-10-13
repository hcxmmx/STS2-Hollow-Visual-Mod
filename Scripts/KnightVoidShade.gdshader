shader_type canvas_item;
void fragment() {
    vec4 tint = COLOR;
    vec4 pixel = texture(TEXTURE, UV);
    vec2 step_uv = TEXTURE_PIXEL_SIZE * 1.4;
    float edge = max(max(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a,
                         texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
                     max(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a,
                         texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a));
    vec3 ink = pixel.rgb + vec3(0.018, 0.024, 0.036) * (1.0 - pixel.rgb);
    COLOR = vec4(mix(vec3(0.24, 0.31, 0.40), ink, pixel.a), max(pixel.a, edge * 0.65)) * tint;
}
