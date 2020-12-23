if (room != rm_finish) {
	var stairs_spot = instance_find(obj_stairs_spot, 0);
 
	// First Time Setup	
	if (!current_room.visited) {    
	    // Flip game object positions as necesarry
	    if (current_room.flip_horizontal) { flip_room_contents_horizontally(); }
	    if (current_room.flip_vertical) { flip_room_contents_vertically(); }
	    if (current_room.rotate != -1) { rotate_room_contents_around_room_center(current_room.rotate); }
		with obj_game_object { 
			image_angle = 0;
		}
		with obj_placeholder { 
			image_angle = 0;
		}
    
	    // Create locked exits if they should exist
	    for (var i = 0; i < 4; i++) {
	        var x_pos = 0;
	        var y_pos = 0;
        
	        if (i == 0) { x_pos = room_width/2; y_pos = 8; }
	        if (i == 1) { x_pos = room_width-8; y_pos = room_height/2; }
	        if (i == 2) { x_pos = room_width/2; y_pos = room_height-8; }
	        if (i == 3) { x_pos = 8; y_pos = room_height/2; }
	        var door = instance_position(x_pos, y_pos, obj_door);
        
	        var exit_to_create_door_for = current_room.locked_exits[i];
	        if (exit_to_create_door_for) {   
	            if !door { door = instance_create_depth(x_pos, y_pos, 0, obj_door); }
	            door.door_for_exit = exit_to_create_door_for;
	            door.locked = exit_to_create_door_for.locked;
	        }
	    }
		
		// Create key in room if it should exist
		if (current_room.has_key) {
			if (!current_room.stairs_spot_obj && get_random_chance_out_of(3)) { 	
				current_room.item_type = obj_key;
				current_room.stairs_spot_obj = obj_chest
			}
			else { 
				with get_random_instance(obj_collectable_spot) {
					var new_key = instance_create_depth(x, y, 4, obj_key);
					with new_key { if (global.controller.current_room.has_special_item) { make_item_special(); } }
					instance_destroy();
					if (instance_number(obj_collectable_spot) == 0) { current_room.has_collectables = false; rooms_with_collectables -= 1; }
				} 
			}
		}
	
		// Create room's stairs_spot object
	    if (current_room.stairs_spot_obj) {
	        instance_create_depth(stairs_spot.x, stairs_spot.y, 5, current_room.stairs_spot_obj);
	    }
    
	    // Create collectables in room if they should exist
	    if (current_room.has_collectables && !current_room.collectables_collected) {
	        with obj_collectable_spot { instance_create_depth(x, y, 0, obj_collectable); instance_destroy(); }
			if (instance_number(obj_collectable) == 0) { current_room.collectables_collected = true; }
	    }
	
		// Remove lit status from room if it shouldn't exist
		if (current_room.lit) { 
			if (instance_number(obj_lantern) == 0) { current_room.lit = false; }
			else { with obj_lantern { light_lantern(true); } }
		}
	
	    // Mark room as one that has been visited at some point during this game
	    current_room.visited = true;
	}

	// Every Time Setup
	background_id = layer_background_get_id(layer_get_id("Background"));
	layer_background_blend( background_id, bg_color);
	with obj_room { distance_to_current_room = 9999; }
	with current_room { calculate_distance_to_current(0); }

	// Change position if necessary
	if entered_from_stairs {
	    global.player.x = stairs_spot.x
		global.player.y = stairs_spot.y
	}

	// Move character into position
	move_player(4);

	// Add a small pause when entering a room
	global.player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;

	// Set initial lighting to darkness
	with obj_game_object { image_blend = global.controller.bg_color; }
}
