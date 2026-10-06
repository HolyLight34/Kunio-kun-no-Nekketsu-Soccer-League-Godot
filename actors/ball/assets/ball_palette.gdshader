shader_type canvas_item;


// 足球原始贴图的固定调色板。
// 只用于识别需要被替换的像素。
const ivec3 SOURCE_WHITE = ivec3(236, 238, 236);
const ivec3 SOURCE_BLACK = ivec3(0, 0, 0);
const ivec3 SOURCE_RED = ivec3(236, 106, 100);


// 是否启用调色板替换。
// false：显示原始贴图。
// true：替换原始调色板。
uniform bool palette_enabled = false;

uniform vec4 white_color : source_color;
uniform vec4 black_color : source_color;
uniform vec4 red_color : source_color;


// 判断当前像素是否与指定的原始 RGB 完全匹配。
bool matches_rgb(vec3 color, ivec3 target_rgb) {
	ivec3 sampled_rgb = ivec3(round(color * 255.0));
	return sampled_rgb == target_rgb;
}


void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (palette_enabled) {
		if (matches_rgb(color.rgb, SOURCE_WHITE)) {
			color.rgb = white_color.rgb;
		}
		else if (matches_rgb(color.rgb, SOURCE_BLACK)) {
			color.rgb = black_color.rgb;
		}
		else if (matches_rgb(color.rgb, SOURCE_RED)) {
			color.rgb = red_color.rgb;
		}
	}

	COLOR = color;
}