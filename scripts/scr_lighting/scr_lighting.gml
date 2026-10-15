/// @function									get_relative_light_intensity(_instance_to_light);
/// @param		{index} _instance_to_light		The instance being lit up by the calling instance
function get_relative_light_intensity(_instance_to_light) {
	if (!is_existing_instance(_instance_to_light)) { return 0; }

	// Get lightning intensity
	var _distance_away = get_distance_to_instance(_instance_to_light);
	var _lighting_intensity = floor(_distance_away/DIMMING_RATE);
	if (_lighting_intensity <= 0) { _lighting_intensity = 0; }
	
	// Get reltive intensity within minimum and maximum
	var _relative_intensity = (lighting_distance <= 0) ? 0 : (1-(_lighting_intensity/lighting_distance));
	if (_relative_intensity > maximum_intensity) { _relative_intensity = maximum_intensity; }
	else if (_relative_intensity < minimum_intensity) { _relative_intensity = minimum_intensity; }
	else if (_relative_intensity <= 0) { _relative_intensity = 0; }

	return _relative_intensity * intensity;
}

/// @function									get_greatest_lighting();
/// @param		{index} obj						The minimum range needed to apply the light source
function get_greatest_lighting(_minimum_range = 0) {
	var _greatest_lighting_intensity = 0;
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_lava), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_fire_skeleton), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_statue), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(obj_light_source, _greatest_lighting_intensity, _minimum_range);
	return _greatest_lighting_intensity;
}


/// @function									get_greatest_lighting_for_object();
/// @param		{index} _obj						The instance or object index to check the lighting for
/// @param		{float} _intensity_to_beat		The current minimum lighting to check for a greater value than
function get_greatest_lighting_for_object(_obj, _intensity_to_beat, _minimum_range = 0) {
	var _greatest_lighting_intensity = _intensity_to_beat
	with _obj {
		var _lighting_intensity = (lighting_range < _minimum_range) ? 0 : get_relative_light_intensity(other.id);
		if (_lighting_intensity > _greatest_lighting_intensity) { _greatest_lighting_intensity = _lighting_intensity; }
	}
	return _greatest_lighting_intensity
}

/// @function									get_image_blend();
function get_image_blend() {
	// Return full lighting image blend on the title screen
	if (instance_number(obj_title) > 0) { return c_white; }

	// Create image blend color based on the greatest available lighting source
	var _col = merge_color(global.bg_color, c_white, get_greatest_lighting()), _controller = global.controller;
	// Invert color if object is causing a screen flash
	if (_controller.flash_obj == id) { 
		_col = merge_color(_col, get_game_bg_color(), power(global.controller.flash_time, 2)/power(SCREEN_FLASH_DURATION, 2)); 
	}
	
	return _col;
}