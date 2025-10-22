shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_frequency : hint_range(0.1, 10.0) = 2.0;

uniform float red_displacement : hint_range(0.0, 0.1) = 0.02;
uniform float green_displacement : hint_range(0.0, 0.1) = 0.02;
uniform float blue_displacement : hint_range(0.0, 0.1) = 0.02;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float slice_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float ghost_intensity : hint_range(0.0, 0.5) = 0.1;
uniform float negative_intensity : hint_range(0.0, 1.0) = 0.0;

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;
	vec4 base_color = texture(TEXTURE, uv);
	vec4 final_color = base_color;
	
	float glitch_time = TIME * glitch_frequency;

	// 永远启用 glitch 效果
	float glitch_active = 1.0;

	// --- glitch 位移部分 ---
	float slice_y = random(vec2(glitch_time * 10.0, 0.0));
	if (abs(uv.y - slice_y) < 0.02 * slice_intensity) {
		float slice_offset = (random(vec2(glitch_time * 15.0, 0.0)) - 0.5) * 0.1 * slice_intensity;
		uv.x += slice_offset;
	}

	float vertical_shift = random(vec2(glitch_time * 8.0, 0.0)) * 0.05 * intensity;
	uv.y += vertical_shift;

	float wave = sin(uv.y * 100.0 + glitch_time * 5.0) * 0.01 * intensity;
	uv.x += wave;

	final_color = texture(TEXTURE, uv);

	// --- 颜色分离 ---
	float shift_amount = red_displacement;
	vec4 red_channel = texture(TEXTURE, uv + vec2(shift_amount, 0.0));
	vec4 green_channel = texture(TEXTURE, uv + vec2(-green_displacement, 0.0));
	vec4 blue_channel = texture(TEXTURE, uv + vec2(blue_displacement, 0.0));

	final_color.r = mix(final_color.r, red_channel.r, intensity);
	final_color.g = mix(final_color.g, green_channel.g, intensity);
	final_color.b = mix(final_color.b, blue_channel.b, intensity);

	// --- 扫描线 ---
	float scanline = sin(uv.y * 300.0 + glitch_time * 2.0) * 0.5 + 0.5;
	final_color.rgb *= 1.0 - scanline * scanline_intensity * intensity;

	// --- 静态噪声 ---
	float static_noise = random(uv + glitch_time) * noise_intensity;
	final_color.rgb += static_noise;

	// --- 残影 ---
	if (ghost_intensity > 0.0) {
		vec4 ghost_color = texture(TEXTURE, uv + vec2(0.01, 0.01)) * ghost_intensity;
		final_color.rgb = mix(final_color.rgb, ghost_color.rgb, ghost_intensity * 0.5);
	}

	// --- 反色 ---
	if (negative_intensity > 0.0) {
		vec4 negative_color = vec4(1.0 - final_color.rgb, final_color.a);
		final_color.rgb = mix(final_color.rgb, negative_color.rgb, negative_intensity);
	}

	// --- 发光 ---
	final_color.rgb += 0.2 * intensity;

	COLOR = final_color;
}
 