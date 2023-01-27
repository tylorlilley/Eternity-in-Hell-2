//
// A shader to replace red with the chosen color, and then apply lighting blending
//
varying vec2 v_vTexcoord; // The original sprite color
varying vec4 v_vColour; // The image_blend color

uniform vec4 new_color;

void main()
{
	// Set up defaults
	vec4 texColor = texture2D(gm_BaseTexture, v_vTexcoord);
	
	// Set a minimum so that the highlight color still shows up in the dark
	vec4 newBlend = vec4(v_vColour.rgb, texColor.a);
	
	// If the original sprite pixel is bright red, replace it with the new color and apply the image blend
	vec4 pixelColor = newBlend * texture2D( gm_BaseTexture, v_vTexcoord );
	if (texColor.g == 0.0 && texColor.b == 0.0 && texColor.a == 1.0) {
		if (newBlend.r < 20.0/255.0) { newBlend.r = 20.0/255.0; }		
		if (newBlend.g < 20.0/255.0) { newBlend.g = 20.0/255.0; }
		if (newBlend.b < 20.0/255.0) { newBlend.b = 20.0/255.0; }
		
		pixelColor = newBlend * new_color;
	}
	
	// Return the new pixel color
    gl_FragColor = vec4(pixelColor.rgb, texColor.a);
}
