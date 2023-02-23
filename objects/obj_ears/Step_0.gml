if (can_process_this_frame()) {
	var fall_asleep = false;
	if (awake && !is_instance_at_coordinates(target_x, target_y, id)) {
		sprite_index = get_sprite_to_use(spr_ears_awake);
		image_index = (x > target_x) ? 1 : -1;
		move_towards_coordinates_on_path(false, true, 4);
		if (target_path == noone) { fall_asleep = true; }
	}
	else { fall_asleep = true; }
	
	if (fall_asleep) {
		sprite_index = get_sprite_to_use(spr_ears);
		awake = false;
	}
	
	event_inherited();
}