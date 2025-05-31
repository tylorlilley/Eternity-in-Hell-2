/// @function									get_relative_light_intensity(instance_to_light);
/// @param		{index} instance_to_light		The instance being lit up by the calling instance
function get_relative_light_intensity(instance_to_light) {
	if (!is_existing_instance(instance_to_light)) { return 0; }

	// Get lightning intensity
	var distance_away = get_distance_to_instance(instance_to_light);
	var lighting_intensity = floor(distance_away/DIMMING_RATE);
	if (lighting_intensity <= 0) { lighting_intensity = 0; }
	
	// Get reltive intensity within minimum and maximum
	var relative_intensity = (1-(lighting_intensity/lighting_distance));
	if (relative_intensity > maximum_intensity) { relative_intensity = maximum_intensity; }
	else if (relative_intensity < minimum_intensity) { relative_intensity = minimum_intensity; }
	else if (relative_intensity <= 0) { relative_intensity = 0; }

	return relative_intensity * intensity;
}

/// @function									get_greatest_lighting();
function get_greatest_lighting(skip_threshold = 0) {
	// Get minimum intensity
	var greatest_lighting_intensity = 0;
	var lava = instance_nearest(x, y, obj_lava); 
	with (lava) { 			
		var lighting_intensity = get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}
	var fire_skeleton = instance_nearest(x, y, obj_fire_skeleton); 
	with (fire_skeleton) { 			
		var lighting_intensity = get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}
	var statue = instance_nearest(x, y, obj_statue); 
	with (statue) { 			
		var lighting_intensity = get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}
	
	
	// Get greatest lighting intensity
	with obj_light_source {
		var lighting_intensity = lighting_range <= skip_threshold ? 0 : get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}
	
	return greatest_lighting_intensity;
}

/// @function									get_image_blend();
function get_image_blend() {
	if (instance_number(obj_title) > 0) { return c_white; }
	
	// Get minimum intensity
	var greatest_lighting_intensity = get_greatest_lighting();
	
	// Get greatest lighting intensity
	with obj_light_source {
		var lighting_intensity = get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}

	// Invert color if object is causing a screen flash
	var col = merge_color(global.bg_color, c_white, greatest_lighting_intensity), controller = global.controller;
	if (controller.flash_obj == id) { 
		col = merge_color(col, get_game_bg_color(), power(global.controller.flash_time, 2)/power(SCREEN_FLASH_DURATION, 2)); 
	}
	
	return col;
}