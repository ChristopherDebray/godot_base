shader_type canvas_item;

// --- Outline controls ---
uniform float outline_thickness : hint_range(0.0, 8.0) = 0.35; // base thickness in pixels
uniform vec4  outline_color     : source_color = vec4(1.0, 0.843, 0.0, 1.0);
uniform float alpha_threshold   : hint_range(0.0, 1.0) = 0.2;   // edge threshold
uniform float feather           : hint_range(0.0, 1.0) = 0.15;  // soft edge width

// --- Pulse controls ---
uniform float pulse_speed   : hint_range(0.0, 10.0) = 3.0; // higher = faster
uniform float pulse_amount  : hint_range(0.0, 1.0)  = 0.5; // 0..1 overall strength
uniform float thickness_pulse_ratio : hint_range(0.0, 1.0) = 0.35; // how much of pulse goes to thickness
uniform float brightness_pulse_ratio: hint_range(0.0, 1.0) = 0.65; // how much of pulse goes to brightness
uniform float pulse_phase   : hint_range(-6.283, 6.283) = 0.0; // per-instance offset (radians)

// --- Base flash/selection ---
uniform float mix_amount : hint_range(0.0, 1.0, 0.01) = 0.0;

// 8 directions for neighborhood sampling
const vec2 DIR8[8] = vec2[8](
    vec2( 1.0,  0.0),
    vec2(-1.0,  0.0),
    vec2( 0.0,  1.0),
    vec2( 0.0, -1.0),
    vec2( 0.70710678,  0.70710678),
    vec2(-0.70710678,  0.70710678),
    vec2( 0.70710678, -0.70710678),
    vec2(-0.70710678, -0.70710678)
);

void fragment() {
    // --- Base sprite sample ---
    vec4 base = texture(TEXTURE, UV);
    vec3 base_rgb = mix(base.rgb, vec3(1.0), mix_amount);
    float base_a  = base.a;

    // Avoid feather == 0 issues
    float f = max(feather, 1e-4);

    // Inside factor (0 outside -> 1 fully inside)
    float inside = smoothstep(alpha_threshold - f, alpha_threshold + f, base_a);

    // --- Pulse calculation ---
    // p in [0..1], remapped with sin
    float p = 0.5 + 0.5 * sin(TIME * pulse_speed + pulse_phase);

    // Thickness “breathing” factor (1.0 = no change)
    float thickness_scale = 1.0 + pulse_amount * thickness_pulse_ratio * (p * 2.0 - 1.0);
    // Brightness factor for the outline color
    float brightness_scale = 1.0 + pulse_amount * brightness_pulse_ratio * (p);

    // --- Neighborhood alpha (outline detection) ---
    vec2 px = TEXTURE_PIXEL_SIZE * (outline_thickness * thickness_scale);
    float neighbor_a = 0.0;
    for (int i = 0; i < 8; i++) {
        neighbor_a = max(neighbor_a, texture(TEXTURE, UV + DIR8[i] * px).a);
    }
    float near_shape = smoothstep(alpha_threshold - f, alpha_threshold + f, neighbor_a);

    // Only outside but near the shape
    float outline_factor = (1.0 - inside) * near_shape;

    // Compose outline color (pulse on brightness) + alpha
    vec3 outline_rgb = outline_color.rgb * brightness_scale;
    float outline_a  = outline_color.a * outline_factor;

    // Final mix (single write, no return)
    vec3 final_rgb = mix(base_rgb, outline_rgb, outline_factor);
    float final_a  = mix(base_a,  outline_a,  outline_factor);
    COLOR = vec4(final_rgb, final_a);
}
