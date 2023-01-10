if (process_this_frame()) {
	var carried_amulet = get_carried_item_of_type(obj_amulet);
	var has_special_amulet = (carried_amulet != noone && carried_amulet.special);
	x_prev = x;
	y_prev = y;
	opened_door_this_frame = false;

	if (instance_place(x, y, obj_solid) && !dead && !has_special_amulet) { kill_player(); }
	if (!dead && !game_has_been_won() && !game_has_been_lost()) {   
	    // Get input from player
	    var dir = -1; 
	    if global.controller.key_space {
	        // do nothing
	    }
	    else if global.controller.key_up && !global.controller.key_down && (global.controller.key_up_pressed || !global.controller.key_up_released) { dir = directions.up; }
	    else if global.controller.key_down && !global.controller.key_up && (global.controller.key_down_pressed || !global.controller.key_down_released) { dir = directions.down; }
	    else if global.controller.key_left && !global.controller.key_right && (global.controller.key_left_pressed || !global.controller.key_left_released) { dir = directions.left; }
	    else if global.controller.key_right && !global.controller.key_left && (global.controller.key_right_pressed || !global.controller.key_right_released) { dir = directions.right; }
		
		// Handle movement pause
		if (pause_movement > 0) { pause_movement -= 1; }
		else if !global.controller.key_space {
			// Handle inventory management
			if (global.controller.key_z_pressed) { pick_up_or_drop_item(directions.left) }
			if (global.controller.key_x_pressed) { pick_up_or_drop_item(directions.right) }
			/*
			if (global.controller.key_z_pressed && image_xscale == 1) ||
			   || (global.controller.key_x_pressed && image_xscale == -1) { 
					pick_up_or_drop_item(directions.left)
			}
			if (global.controller.key_z_pressed && image_xscale == -1) ||
			   (global.controller.key_x_pressed && image_xscale == 1) { 
					pick_up_or_drop_item(directions.right)
			}
			*/
			
		    // Move player in chosen direction if possible
		    if (can_move_in_direction(dir, false, true)) { move_player(dir); }
		}
		
		// Increase lighting range if carrying a rosary
		var carried_rosary = get_carried_item_of_type(obj_rosary)
		lighting_range = global.controller.PLAYER_LIGHT_RANGE;
		if (carried_rosary) { lighting_range += (carried_rosary.special) ? 2 : 1; }
		is_flickering_light_source = false;
		// Increase lighting range if carrying two torches
		if (carried_items[directions.right] && carried_items[directions.right].object_index == obj_torch && carried_items[directions.right].light_source  &&
			carried_items[directions.left] && carried_items[directions.left].object_index == obj_torch && carried_items[directions.left].light_source) { 
			
			if (lighting_range < carried_items[directions.right].light_source.lighting_range+4) { 
				lighting_range = carried_items[directions.right].light_source.lighting_range+4;
				is_flickering_light_source = true;
			}
			if (lighting_range < carried_items[directions.left].light_source.lighting_range+4) { 
				lighting_range = carried_items[directions.left].light_source.lighting_range+4;
				is_flickering_light_source = true;
			}
		}
		
		// Destroy lava if standing on it
		if (carried_amulet != noone) { consume_lava(false); }
    
	    // Transition to new room depending on player position
	    var stairs = instance_place(x, y, obj_stairs);
		if (stairs && stairs.active && instance_at_coordinates(x, y, stairs)) { global.controller.transition = directions.stairs; }
	    else if x < 0 { global.controller.transition = directions.left; }
	    else if x > room_width { global.controller.transition = directions.right; }
	    else if y < 0 { global.controller.transition = directions.up; }
	    else if y > room_height { global.controller.transition = directions.down; }
		
		// Update bush hiding status
		// var bush_at_quadrant = get_presence_at_each_quadrant(obj_bush);
		// hidden = (bush_at_quadrant[0] && bush_at_quadrant[1] && bush_at_quadrant[2] && bush_at_quadrant[3]);
		hidden = false;
	}
	else if dead image_index = 2;

	event_inherited();
}
