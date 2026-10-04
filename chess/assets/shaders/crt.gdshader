// Old TV look: dark scanlines and darker corners, drawn over the whole screen.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
// Screen pixels per scanline (one game pixel is 8 screen pixels at 1280x720).
uniform float scanline_period = 4.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.6;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float line = 0.5 + 0.5 * sin(FRAGCOORD.y * 6.28318 / scanline_period);
	color.rgb *= 1.0 - scanline_strength * line;
	vec2 from_center = SCREEN_UV - vec2(0.5);
	color.rgb *= 1.0 - vignette_strength * dot(from_center, from_center);
	COLOR = vec4(color.rgb, 1.0);
}
