shader_type canvas_item;
// Tô lại màu cánh hoa trắng trong ảnh vẽ tay theo gen màu của cây,
// và làm cây ngả nâu khi héo, già hoặc chết.

uniform bool use_tint = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool rainbow = false;
uniform float fade = 0.0;      // 0 = tươi, 1 = nâu hẳn
uniform bool silhouette = false;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * clamp(p - 1.0, 0.0, 1.0);
}

void fragment() {
	vec4 c = COLOR;
	if (use_tint) {
		vec3 hsv = rgb2hsv(c.rgb);
		// vùng cánh hoa: gần như không màu và sáng
		float mask = (1.0 - smoothstep(0.10, 0.24, hsv.y)) * smoothstep(0.55, 0.80, hsv.z);
		vec3 t = tint.rgb;
		if (rainbow) {
			t = hsv2rgb(vec3(fract(UV.x * 0.9 + UV.y * 0.6), 0.45, 1.0));
		}
		float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tinted = t * clamp(lum * 1.06, 0.0, 1.0);
		c.rgb = mix(c.rgb, tinted, mask);
	}
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(g) * vec3(1.0, 0.82, 0.58), fade);
	if (silhouette) {
		c.rgb = vec3(0.25, 0.27, 0.25);
	}
	COLOR = c;
}
