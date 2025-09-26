shader_type canvas_item;

uniform sampler2D noise: repeat_enable;
uniform float amount: hint_range(0.0, 5.0, 0.01) = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	//1.0 = the speed of the shader
	vec4 noise_color = texture(noise, UV + vec2(0.3) * sin(TIME));
	//vec4 texture_color = texture(TEXTURE, UV + vec2(noise_color.r));
	vec4 texture_color = texture(TEXTURE, UV + vec2(noise_color.r - 0.5) * amount);
	COLOR = texture_color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
