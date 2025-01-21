/// @description Step

// If room becomes fully lit, destroy self
var current_room = global.controller.current_room;
if ((!eye_chest && current_room.lit) || (eye_chest && instance_number(obj_giant_eye) == 0)) {
	destroy_instances_at_position();
	var new_inst = instance_create(x, y, obj_chest);
	current_room.remove_from_instances_at_map_positions(id);
	current_room.add_to_instances_at_map_positions(new_inst);
	current_room.reset_room_solid_path_grid(); 
	current_room.reset_room_lava_path_grid();
	play_sound(snd_appear, false);
	with (new_inst) { screen_flash(); }
	instance_destroy();
}