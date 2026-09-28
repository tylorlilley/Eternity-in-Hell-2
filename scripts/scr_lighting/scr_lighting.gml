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
/// @param		{index} obj						The minimum range needed to apply the light source
function get_greatest_lighting(minimum_range = 0) {
	var greatest_lighting_intensity = 0;
	greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_lava), greatest_lighting_intensity, minimum_range);
	greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_fire_skeleton), greatest_lighting_intensity, minimum_range);
	greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_statue), greatest_lighting_intensity, minimum_range);
	greatest_lighting_intensity = get_greatest_lighting_for_object(obj_light_source, greatest_lighting_intensity, minimum_range);
	return greatest_lighting_intensity;
}


/// @function									get_greatest_lighting_for_object();
/// @param		{index} obj						The instance or object index to check the lighting for
/// @param		{float} intensity_to_beat		The current minimum lighting to check for a greater value than
function get_greatest_lighting_for_object(obj, intensity_to_beat, minimum_range = 0) {
	var greatest_lighting_intensity = intensity_to_beat
	with obj {
		var lighting_intensity = (lighting_range <= minimum_range) ? 0 : get_relative_light_intensity(other.id);
		if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}
	return greatest_lighting_intensity
}

/// @function									get_image_blend();
function get_image_blend() {
	if (instance_number(obj_title) > 0) { return c_white; }

	// Invert color if object is causing a screen flash
	var col = merge_color(global.bg_color, c_white, get_greatest_lighting()), controller = global.controller;
	if (controller.flash_obj == id) { 
		col = merge_color(col, get_game_bg_color(), power(global.controller.flash_time, 2)/power(SCREEN_FLASH_DURATION, 2)); 
	}
	
	return col;
}