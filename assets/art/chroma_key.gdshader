shader_type canvas_item;
// Generated RGB sprite sheets use a magenta key. The source PNG remains intact.
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float magenta = min(sample_color.r, sample_color.b) - sample_color.g;
	float key = smoothstep(0.34, 0.62, magenta) * smoothstep(0.65, 0.9, max(sample_color.r, sample_color.b));
	COLOR *= vec4(1.0, 1.0, 1.0, 1.0 - key);
}
