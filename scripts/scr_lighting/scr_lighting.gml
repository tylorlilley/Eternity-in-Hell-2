/// @function									obj_game_object_get_relative_light_intensity(instance_to_light, maximum_intensity);
/// @param		{index} instance_to_light		The instance being lit up by the calling instance
/// @param		{real} maximum_intensity		The maximum brightness to be returned for the instance the calling instance is lighting up
function obj_game_object_get_relative_light_intensity(instance_to_light, maximum_intensity) {
	var flicker = floor(flicker_value / 25);
	var distance_away = distance_to_instance(instance_to_light);

	var lighting_intensity = floor(distance_away/global.controller.DIMMING_RATE);
	var lighting_distance = (lighting_range + flicker);

	if (lighting_distance <= 0) { return 0; }
	var relative_intensity = (maximum_intensity-(lighting_intensity/lighting_distance));
	if (relative_intensity <= 0) { relative_intensity = 0; }

	return relative_intensity;
}

/// @function									obj_game_object_calculate_lighting(maximum_intensity);
/// @param		{real} maximum_intensity		The maximum brightness that can be set for the calling instance
function obj_game_object_calculate_lighting(maximum_intensity) {
	var greatest_lighting_intensity = 0;

	with obj_light_source {
	    var lighting_intensity = obj_game_object_get_relative_light_intensity(other, maximum_intensity);
	    if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}

	if greatest_lighting_intensity > maximum_intensity { greatest_lighting_intensity = maximum_intensity; }
	image_blend = merge_color(__background_get_colour( ), c_white, greatest_lighting_intensity);
}