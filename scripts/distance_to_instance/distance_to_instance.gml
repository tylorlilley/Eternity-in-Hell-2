/// @description  distance_to_instance(instance)
function distance_to_instance(argument0) {
	var instance = argument0;

	if (!instance_exists(instance)) { return -1; }
	if (self.id == instance.id) { return 0; }

	return sqrt((sqr(instance.x - x) + sqr(instance.y - y)));




}
