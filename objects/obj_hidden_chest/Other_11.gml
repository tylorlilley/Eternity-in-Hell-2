/// @description Step

// If room becomes fully lit, destroy self
var _current_room = global.controller.current_room;
if ((!eye_chest && !mirror_chest && !cross_chest && _current_room.lit) || 
	(eye_chest && instance_number(obj_giant_eye) == 0) || 
	(mirror_chest && !_current_room.has_hall_of_mirrors) ||
	(cross_chest && instance_number(obj_inverted_cross) == 0 && instance_number(obj_echo_generator) == 0)) {
	destroy_instances_at_position();
	var _new_inst = instance_create(x, y, obj_chest);
	_current_room.remove_from_instances_at_map_positions(id);
	_current_room.add_to_instances_at_map_positions(_new_inst);
	mark_current_room_for_grid_update();
	play_sound(snd_appear, false);
	with (_new_inst) { screen_flash(); }
	instance_destroy();
}