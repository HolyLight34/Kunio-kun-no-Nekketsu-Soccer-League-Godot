shader_type canvas_item;

uniform vec4 from_color : source_color = vec4(0.9255, 0.9333, 0.9255, 1.0);
uniform vec4 to_color : source_color = vec4(0.92549, 0.41569, 0.39216, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (distance(color.rgb, from_color.rgb) < 0.01) {
		color.rgb = to_color.rgb;
	}

	COLOR = color;
}