shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float mix_value: hint_range(0.0, 1.0, 0.01) = 0.2;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 noise_color = texture(noise, UV + vec2(1.0) * sin(TIME));
	vec4 texture_color = texture(TEXTURE, UV);
	COLOR = mix(noise_color, texture_color, mix_value);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
