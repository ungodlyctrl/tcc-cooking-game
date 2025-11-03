shader_type canvas_item;

uniform bool show_outline = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.02; // espessura do contorno
uniform float margin : hint_range(0.0, 0.3) = 0.05;   // distância do contorno
uniform float blink_speed : hint_range(0.1, 10.0) = 2.0;

void fragment() {
	vec4 col = vec4(0.0);
	if (show_outline) {
		float blink = sin(TIME * blink_speed * 6.28318) * 0.5 + 0.5;
		float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));

		float outer_edge = margin;
		float inner_edge = margin - thickness;
		float ring = smoothstep(inner_edge, inner_edge + 0.002, edge)
				   - smoothstep(outer_edge, outer_edge + 0.002, edge);
		ring = clamp(ring, 0.0, 1.0);

		col = vec4(outline_color.rgb, outline_color.a * blink * ring);
	}
	COLOR = col;
}

