shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // default white
uniform float mix_amount : hint_range(0.0, 1.0, 0.01) = 0.0;       // 0 = off

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    base *= COLOR; // keep node modulate/self_modulate support
    vec3 mixed_rgb = mix(base.rgb, tint_color.rgb, mix_amount);
    COLOR = vec4(mixed_rgb, base.a);
}
