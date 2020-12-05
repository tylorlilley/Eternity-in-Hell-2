/// @description  obj_game_object_get_relative_light_intensity(instance_to_light, maximum_intensity)
function obj_game_object_get_relative_light_intensity(argument0, argument1) {
	var instance_to_light = argument0, maximum_intensity = argument1;


	var flicker = floor(global.controller.fuzz_value / 25);
	var distance_away = distance_to_instance(instance_to_light);

	var lighting_intensity = floor(distance_away/global.controller.DIMMING_RATE);
	var lighting_distance = (lighting_range + flicker);

	if (lighting_distance <= 0) { return 0; }
	var relative_intensity = (maximum_intensity-(lighting_intensity/lighting_distance));
	if (relative_intensity <= 0) { relative_intensity = 0; }

	return relative_intensity 



}
