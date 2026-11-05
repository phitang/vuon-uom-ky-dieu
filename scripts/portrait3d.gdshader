shader_type canvas_item;
// Ánh sáng khối cho chân dung nhân vật: coi độ trong suốt đã làm mờ như "độ phồng"
// của hình, tính pháp tuyến từ đó rồi chiếu sáng từ trên-trái, thêm điểm bóng và viền sáng.
// (Mọi phép lấy mẫu nằm trong fragment() để chạy được trên renderer Compatibility/điện thoại.)

uniform float radius = 14.0;     // độ rộng vùng phồng (điểm ảnh của ảnh gốc)
uniform float bump = 3.2;        // độ nổi khối
uniform vec3 light_dir = vec3(-0.55, -0.7, 0.75);

void fragment() {
	vec4 c = COLOR;
	if (c.a > 0.01) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		// độ phồng tại 4 điểm: phải, trái, dưới, trên
		vec2 offs[4] = vec2[4](vec2(3.0, 0.0), vec2(-3.0, 0.0), vec2(0.0, 3.0), vec2(0.0, -3.0));
		float hh[4];
		for (int k = 0; k < 4; k++) {
			vec2 uv = UV + offs[k] * px;
			float s = texture(TEXTURE, uv).a * 2.0;
			for (int i = 0; i < 12; i++) {
				float a = float(i) * 0.5236;
				s += texture(TEXTURE, uv + vec2(cos(a), sin(a)) * px * radius).a;
				s += texture(TEXTURE, uv + vec2(cos(a + 0.26), sin(a + 0.26)) * px * radius * 0.5).a;
			}
			hh[k] = s / 26.0;
		}
		float hx = hh[0] - hh[1];
		float hy = hh[2] - hh[3];
		vec3 n = normalize(vec3(-hx * bump, -hy * bump, 1.0));
		vec3 l = normalize(light_dir);                 // hướng từ bề mặt tới đèn (trên-trái, phía trước)
		float diff = clamp(dot(n, l), 0.0, 1.0);
		float spec = pow(max(dot(reflect(-l, n), vec3(0.0, 0.0, 1.0)), 0.0), 18.0);
		vec3 rim_dir = normalize(vec3(0.8, 0.2, 0.3));  // viền sáng phía sau bên phải
		float rim = pow(clamp(dot(n, rim_dir), 0.0, 1.0), 2.5);
		vec3 lit = c.rgb * (0.52 + 0.62 * diff);
		lit += vec3(1.0, 0.97, 0.9) * spec * 0.22;
		lit += vec3(1.0, 0.92, 0.75) * rim * 0.25;
		c.rgb = lit;
	}
	COLOR = c;
}
