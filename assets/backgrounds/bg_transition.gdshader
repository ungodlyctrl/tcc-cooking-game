// Godot 4 canvas_item shader
shader_type canvas_item;

uniform sampler2D tex_a;
uniform sampler2D tex_b;
uniform float blend : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 ca = texture(tex_a, UV);
    vec4 cb = texture(tex_b, UV);

    // crossfade suave entre as duas textures
    COLOR = mix(ca, cb, blend);
}

