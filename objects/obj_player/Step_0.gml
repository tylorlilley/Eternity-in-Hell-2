if (can_process_this_frame()) {
	x_prev = x;
	y_prev = y;
	dir_prev = dir;
	if (dir_prev == directions.none) { dir_prev = irandom(3); }
	
	// Spawn Bugs in nearby dirt and bushes
	with (obj_player_corpse) { 
		if (has_bug && point_distance(x, y, global.player.x, global.player.y) <= global.controller.TRAP_RANGE) {
			instance_create(x, y, obj_bug);
			instance_create(x, y, obj_bug);
			has_bug = false;
		}
	}
	with (obj_bones) { 
		if (has_bug && point_distance(x, y, global.player.x, global.player.y) <= global.controller.TRAP_RANGE) {
			instance_create(x, y, obj_bug);
			has_bug = false;
		}
	}
	with (obj_dirt) { 
		if (has_bug && point_distance(x, y, global.player.x, global.player.y) <= global.controller.TRAP_RANGE) {
			instance_create(x, y, obj_bug);
			has_bug = false;
		}
	}
	with (obj_bush) { 
		if (has_bug && point_distance(x, y, global.player.x, global.player.y) <= global.controller.TRAP_RANGE) {
			instance_create(x, y, obj_bug);
			has_bug = false;
		}
	}

	if (!dead && is_solid_at_position(x, y)) {
		var killed_by_obj = instance_place(x, y, obj_solid).object_index;
		killed_by_obj = (killed_by_obj == obj_giant_worm_head) ? obj_giant_worm_body : killed_by_obj;
		play_sound(snd_crunch, false);
		kill_player(killed_by_obj);
	}
	if (!dead && !is_game_won() && !is_game_lost()) {   
	    // Get input from player
	    dir = get_direction_input(false);
		
		// Handle movement pause
		if (pause_movement > 0) { pause_movement -= 1; }
		else {
			// Handle inventory management
			if (global.controller.key_z_pressed) { 
				if (!can_drop_item(left_hand_item)) { play_sound(snd_locked, false); }
				else { pick_up_or_put_down_item(directions.left); }
			}
			if (global.controller.key_x_pressed) { 
				if (!can_drop_item(right_hand_item)) { play_sound(snd_locked, false); }
				else { pick_up_or_put_down_item(directions.right); }
			}
			
		    // Move player in chosen direction if possible
		    if (!is_existing_instance(moved_by) && dir != directions.none && can_move_in_direction(dir, false, true)) { move_player(dir); moved_by = id; }
		}
		
		// Increase lighting range if carrying a rosary
		lighting_range = global.controller.PLAYER_LIGHT_RANGE;
		if (is_carrying_item(obj_rosary)) { lighting_range += (is_carrying_special_item(obj_rosary)) ? 2 : 1; }
		is_flickering_light_source = false;
		
		// Increase lighting range if carrying two torches
		if (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source) &&
			is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source)) { 
				if (lighting_range < right_hand_item.light_source.lighting_range+4) { 
					lighting_range = right_hand_item.light_source.lighting_range+4;
					is_flickering_light_source = true;
				}
				if (lighting_range < left_hand_item.light_source.lighting_range+4) { 
					lighting_range = left_hand_item.light_source.lighting_range+4;
					is_flickering_light_source = true;
				}
		}
    
	    // Transition to new room depending on player position
	    var stairs = instance_place(x, y, obj_stairs), hole = instance_place(x, y, obj_hole);
		if (is_existing_instance(stairs) && stairs.active && is_instance_at_coordinates(x, y, stairs)) { global.controller.transition = directions.stairs; }
		if (is_existing_instance(hole) && hole.active && is_existing_instance(hole.connected_hole) && is_instance_at_coordinates(x, y, hole)) { global.controller.transition = directions.stairs; global.controller.transition_hole = hole; }
	    else if x < 0 { global.controller.transition = directions.left; }
	    else if x > room_width { global.controller.transition = directions.right; }
	    else if y < 0 { global.controller.transition = directions.up; }
	    else if y > room_height { global.controller.transition = directions.down; }
	}
	else if dead image_index = 2;

	event_inherited();
}
