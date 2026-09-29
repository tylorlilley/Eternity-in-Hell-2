//
// A shader to replace red with the chosen color, and then apply lighting blending
//
varying vec2 v_vTexcoord; // The texture coordinate of the original sprite pixel
varying vec4 v_vColour; // The image_blend color (rgb) and the white/red swap flag (a, see DRAW_ALPHA_SWAPPED)

uniform vec4 new_color;
uniform vec4 bg_color;
uniform float color_fade;

void main()
{
	// Set up defaults
	vec4 texColor = texture2D(gm_BaseTexture, v_vTexcoord);
	float new_color_minimum = (color_fade / 100.0);
	
	// If drawn with an alpha below 0.75, swap bright white and bright red pixels before any recoloring or lighting
	// The alpha is free to use as a flag since the final alpha always comes from the sprite itself
	if (v_vColour.a < 0.75) {
		if (texColor.r == 1.0 && texColor.g == 1.0 && texColor.b == 1.0 && texColor.a == 1.0) { texColor = vec4(1.0, 0.0, 0.0, 1.0); }
		else if (texColor.r == 1.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) { texColor = vec4(1.0, 1.0, 1.0, 1.0); }
	}

	// Set a minimum so that the highlight color still shows up in the dark
	vec4 newBlend = vec4(v_vColour.rgb, texColor.a);
	
	vec4 pixelColor = newBlend * texColor;
	if (texColor.r == 1.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) {
		// If the original sprite pixel is bright red, replace it with the new color and apply the image blend
		if (newBlend.r < new_color_minimum) { newBlend.r = new_color_minimum; }		
		if (newBlend.g < new_color_minimum) { newBlend.g = new_color_minimum; }
		if (newBlend.b < new_color_minimum) { newBlend.b = new_color_minimum; }
		
		pixelColor = newBlend * new_color;
	}
	else if (texColor.r == 0.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) {
		// If the original sprite pixel is solid blck, replace it with the bg color
		pixelColor = bg_color;
	}
	
	// Return the new pixel color
    gl_FragColor = vec4(pixelColor.rgb, texColor.a);
}
