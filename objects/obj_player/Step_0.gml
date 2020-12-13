if (process_this_frame()) {
	x_prev = x;
	y_prev = y;

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
		else {
		    // Move player in chosen direction if possible
		    if (can_move_in_direction(dir, false, true)) { 
		        move_in_direction(dir); 
		        image_index += 1;
		        if (image_index > 1) { image_index = 0; }
		    }
		}
    
	    // Transition to new room depending on player position
	    var stairs = instance_place(x, y, obj_stairs);
		if (stairs && stairs.active && instance_at_coordinates(x, y, stairs)) { global.controller.transition = directions.stairs; }
	    else if x < 0 { global.controller.transition = directions.left; }
	    else if x > room_width { global.controller.transition = directions.right; }
	    else if y < 0 { global.controller.transition = directions.up; }
	    else if y > room_height { global.controller.transition = directions.down; }

	    // Move carried item to current position
	    set_instance_to_same_position(carried_item);
	}
	else if dead image_index = 2;

	event_inherited();
}
