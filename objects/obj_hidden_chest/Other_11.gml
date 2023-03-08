/// @description Step

// If room becomes fully lit, destroy self
var controller = global.controller;
if (controller.current_room.lit) {
	destroy_instances_at_position();
	var new_inst = instance_create(x, y, obj_chest);
	controller.current_room.remove_from_instances_at_map_positions(id);
	controller.current_room.add_to_instances_at_map_positions(new_inst);
	play_sound(snd_appear, false);
	with (new_inst) { screen_flash(); }
	instance_destroy();
}