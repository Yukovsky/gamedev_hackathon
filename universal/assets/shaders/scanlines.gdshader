shader_type canvas_item;

uniform float scanline_density : hint_range(1.0, 10.0) = 4.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	
	// Horizontal scanlines
	float scanline = sin(UV.y * 3.14159265 * scanline_density);
	scanline = smoothstep(0.0, 1.0, scanline);
	
	// Darken the scanlines
	base_color.rgb *= mix(1.0, 0.82, scanline * scanline_opacity);
	
	COLOR = base_color;
}
