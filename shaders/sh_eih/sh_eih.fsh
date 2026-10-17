//
// Recolors sprites: bright red pixels take the chosen color, solid black pixels take the background color, and every
// pixel is blended with the image blend, which carries the lighting
//
varying vec2 v_vTexcoord; // The texture coordinate of the original sprite pixel
varying vec4 v_vColour; // The image_blend color (rgb) and a flag (a): the white/red swap (see INVERTED_COLORS_ALPHA_FLAG) or fading (see FADING_COLORS_ALPHA_FLAG)

uniform vec4 new_color;		// The color bright red pixels become
uniform vec4 bg_color;		// The color solid black pixels become
uniform float color_fade;	// The lowest brightness, out of 100, a recolored pixel's blend can fall to, so it still shows in the dark

void main()
{
	// The sprite's pixel, and the lowest blend a recolored pixel may have
	vec4 texColor = texture2D(gm_BaseTexture, v_vTexcoord);
	float new_color_minimum = (color_fade / 100.0);

	// The alpha is free to use as a flag since the final alpha always comes from the sprite itself. Below 0.25, the sprite
	// is fading: bright red pixels have no lowest brightness either, so the image blend can fade every pixel to the background
	bool is_fading = (v_vColour.a < 0.25);

	// If drawn with an alpha from 0.25 to below 0.75, swap bright white and bright red pixels before any recoloring or lighting
	if (!is_fading && v_vColour.a < 0.75) {
		if (texColor.r == 1.0 && texColor.g == 1.0 && texColor.b == 1.0 && texColor.a == 1.0) { texColor = vec4(1.0, 0.0, 0.0, 1.0); }
		else if (texColor.r == 1.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) { texColor = vec4(1.0, 1.0, 1.0, 1.0); }
	}

	// Blend every pixel with the image blend
	vec4 newBlend = vec4(v_vColour.rgb, texColor.a);
	
	vec4 pixelColor = newBlend * texColor;
	if (texColor.r == 1.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) {
		// If the original sprite pixel is bright red, replace it with the new color, blended no darker than the minimum
		// so the highlight color still shows up in the dark, unless the sprite is fading
		if (!is_fading) {
			if (newBlend.r < new_color_minimum) { newBlend.r = new_color_minimum; }
			if (newBlend.g < new_color_minimum) { newBlend.g = new_color_minimum; }
			if (newBlend.b < new_color_minimum) { newBlend.b = new_color_minimum; }
		}

		pixelColor = newBlend * new_color;
	}
	else if (texColor.r == 0.0 && texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) {
		// If the original sprite pixel is solid black, replace it with the background color
		pixelColor = bg_color;
	}
	
	// The new pixel color, with the sprite's own alpha
    gl_FragColor = vec4(pixelColor.rgb, texColor.a);
}
