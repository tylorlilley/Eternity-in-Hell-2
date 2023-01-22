if (can_process_this_frame()) {
	if (awake && !is_instance_at_coordinates(target_x, target_y, id)) {
		sprite_index = get_sprite_to_use(spr_ears_awake);
		image_index = (x > target_x) ? 1 : -1;
		// TODO: Explore making corporeal again if we create better pathfinding for this function
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
	}
	else {
		sprite_index = get_sprite_to_use(spr_ears);
		awake = false;
	}
	
	event_inherited();
}