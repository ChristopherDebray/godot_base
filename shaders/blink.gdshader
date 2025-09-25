shader_type canvas_item;

uniform vec4 color: source_color;
uniform float mix_amount: hint_range(0.0, 1.0, 0.01) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 mixed_rgb = mix(texture_color.rgb, color.rgb, mix_amount);
	COLOR = vec4(mixed_rgb, texture_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
