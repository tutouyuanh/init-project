shader_type canvas_item;
uniform sampler2D world_screen : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size = 3.0;
void fragment() {
	vec2 uv = (floor(SCREEN_UV / (SCREEN_PIXEL_SIZE * pixel_size)) + 0.5) * SCREEN_PIXEL_SIZE * pixel_size;
	vec3 rgb = texture(world_screen, uv).rgb;
	COLOR = vec4(floor(rgb * 23.0 + 0.5) / 23.0, 1.0);
}
