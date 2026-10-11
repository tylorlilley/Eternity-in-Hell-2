/// @function get_relative_light_intensity(_instance_to_light)
/// @description How strongly the calling light source lights an instance. Its light dims one step every DIMMING_RATE
///	pixels, fades out over its lighting distance (counted in those steps), stays between its minimum and maximum
///	intensity, and is scaled by its intensity.
/// @param {Id.Instance} _instance_to_light The instance being lit by the calling light source
/// @returns {real} The light's intensity on the instance, or 0 if the instance doesn't exist
function get_relative_light_intensity(_instance_to_light) {
	if (!is_existing_instance(_instance_to_light)) { return 0; }

	// Count how many steps the light has dimmed by the time it reaches the instance
	var _distance_away = get_distance_to_instance(_instance_to_light);
	var _lighting_intensity = floor(_distance_away/DIMMING_RATE);
	if (_lighting_intensity <= 0) { _lighting_intensity = 0; }
	
	// Get the relative intensity, kept between the light source's minimum and maximum intensity
	var _relative_intensity = (lighting_distance <= 0) ? 0 : (1-(_lighting_intensity/lighting_distance));
	if (_relative_intensity > maximum_intensity) { _relative_intensity = maximum_intensity; }
	else if (_relative_intensity < minimum_intensity) { _relative_intensity = minimum_intensity; }
	else if (_relative_intensity <= 0) { _relative_intensity = 0; }

	return _relative_intensity * intensity;
}

/// @function get_greatest_lighting([_minimum_range])
/// @description The strongest light on the calling instance, from the nearest lava, the nearest fire skeleton, the
///	nearest statue, and every light source
/// @param {real} [_minimum_range] The least lighting range a light source needs for its light to count (0 by default)
/// @returns {real} The greatest light intensity on the instance, or 0 if no light reaches it
function get_greatest_lighting(_minimum_range = 0) {
	var _greatest_lighting_intensity = 0;
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_lava), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_fire_skeleton), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(instance_nearest(x, y, obj_statue), _greatest_lighting_intensity, _minimum_range);
	_greatest_lighting_intensity = get_greatest_lighting_for_object(obj_light_source, _greatest_lighting_intensity, _minimum_range);
	return _greatest_lighting_intensity;
}


/// @function get_greatest_lighting_for_object(_obj, _intensity_to_beat, [_minimum_range])
/// @description The strongest light that a light source instance, or any instance of an object, gives the calling
///	instance, when it beats the strongest light found so far
/// @param {Id.Instance|Asset.GMObject} _obj The light source instance, or the object whose instances to check
/// @param {real} _intensity_to_beat The greatest light intensity found so far
/// @param {real} [_minimum_range] The least lighting range a light source needs for its light to count (0 by default)
/// @returns {real} The greatest intensity found, or _intensity_to_beat if none is greater
function get_greatest_lighting_for_object(_obj, _intensity_to_beat, _minimum_range = 0) {
	var _greatest_lighting_intensity = _intensity_to_beat
	with _obj {
		var _lighting_intensity = (lighting_range < _minimum_range) ? 0 : get_relative_light_intensity(other.id);
		if (_lighting_intensity > _greatest_lighting_intensity) { _greatest_lighting_intensity = _lighting_intensity; }
	}
	return _greatest_lighting_intensity
}

/// @function get_image_blend()
/// @description The color to blend the calling instance's sprite with. It shades from the background color when unlit
///	to white when fully lit, so instances fade into the dark, and it's plain white on the title screen.
/// @returns {real} The blend color
function get_image_blend() {
	if (instance_number(obj_title) > 0) { return c_white; }

	// Draw the instance causing a screen flash in the game's background color, so it stands out against the flash's
	// white until the flash fades
	var _col = merge_color(global.bg_color, c_white, get_greatest_lighting()), _controller = global.controller;
	if (_controller.flash_obj == id) { 
		_col = merge_color(_col, get_game_bg_color(), power(global.controller.flash_time, 2)/power(SCREEN_FLASH_DURATION, 2)); 
	}
	
	return _col;
}