/// @description  obj_game_object_calculate_lighting(maximum_intensity)
function obj_game_object_calculate_lighting(argument0) {
	var maximum_intensity = argument0;

	var greatest_lighting_intensity = 0;

	with obj_light_source {
	    var lighting_intensity = obj_game_object_get_relative_light_intensity(other, maximum_intensity);
	    if (lighting_intensity > greatest_lighting_intensity) { greatest_lighting_intensity = lighting_intensity; }
	}

	if greatest_lighting_intensity > maximum_intensity { greatest_lighting_intensity = maximum_intensity; }
	image_blend = merge_color(__background_get_colour( ), c_white, greatest_lighting_intensity);



}
