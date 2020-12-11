if (process_this_frame()) {
	x_prev = x;
	y_prev = y;

	if (!dead && !game_has_been_won() && !game_has_been_lost()) {   
	    // Get input from player
	    var dir = -1; 
	    if global.controller.key_space {
	        // do nothing
	    }
	    else if global.controller.key_up && !global.controller.key_down { dir = 0; }
	    else if global.controller.key_down && !global.controller.key_up { dir = 2; }
	    else if global.controller.key_left && !global.controller.key_right { dir = 3; }
	    else if global.controller.key_right && !global.controller.key_left { dir = 1; }
    
		// Handle movement pause
		if (pause_movement > 0) { pause_movement -= 1; }
		else {
		    // Move player in chosen direction if possible
		    if (obj_game_object_can_move_in_direction(dir, false)) { 
		        obj_game_object_move_in_direction(dir); 
		        image_index += 1;
		        if (image_index > 1) { image_index = 0; }
		    }
		}
    
	    // Transition to new room depending on player position
	    var stairs = instance_place(x, y, obj_stairs);
		if (stairs && stairs.active && instance_at_coordinates(x, y, stairs)) { global.controller.transition = 4; }
	    else if x < 0 { global.controller.transition = 3; }
	    else if x > room_width { global.controller.transition = 1; }
	    else if y < 0 { global.controller.transition = 0; }
	    else if y > room_height { global.controller.transition = 2; }

	    // Move carried item to current position
	    obj_game_object_set_instance_to_same_position(carried_item);
	}
	else if dead image_index = 2;

	event_inherited();
}
