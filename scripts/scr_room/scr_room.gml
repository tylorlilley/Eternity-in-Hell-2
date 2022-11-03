function GameRoom(given_x, given_y) constructor {
	//room_reference = noone;
	instances = array_create(0);
	virtual_x = given_x;
	virtual_y = given_y;
	id = generate_id();
	distance_to_current_room = 9999;

	// Initialize room state values
	visited = false;
	flip_horizontal = false;
	flip_vertical = false;
	rotate = noone;
	lit = get_random_chance_out_of(5);

	// Room content values
	has_key = false;
	has_special_item = false;
	has_collectables = false;
	stairs_spot_obj = noone;
	item_type = noone;

	// Initialize room topography information
	exits = [false, false, false, false, false];
	locked_exits = [noone, noone, noone, noone, noone];
	adj_rooms = [noone, noone, noone, noone, noone];
	
	/// @function								get_virtual_quadrant_x_pos(quadrant_number);
	/// @param		{real}	quadrant_number		The number of the quadrant to get the x position for
	function get_virtual_quadrant_x_pos(quadrant_number) {
	    if (quadrant_number mod 2 == 0) { return virtual_x-4; }
		else { return virtual_x+4; }
	}

	/// @function								get_virtual_quadrant_y_pos(quadrant_number);
	/// @param		{real}	quadrant_number		The number of the quadrant to get the x position for
	function get_virtual_quadrant_y_pos(quadrant_number) {
	    if (quadrant_number < 2) { return virtual_y-4; }
		else { return virtual_y+4; }
	}
	
	/// @function								initialize_room(list_of_rooms);
	/// @param	{index}	list_of_rooms			The list of available rooms
	function initialize_room(list_of_rooms) {
		// Randomly decide if room will have collectables, stairs, keys, items, etc
		rand = irandom(100);
		if (rand < global.controller.HAS_STAIRS_PROBABILITY) { exits[4] = true; stairs_spot_obj = obj_stairs; }
		else if (rand < global.controller.HAS_STAIRS_PROBABILITY+global.controller.HAS_ITEM_PROBABILITY) { 
			stairs_spot_obj = obj_chest;
			//if (get_random_chance_out_of(global.controller.SPECIAL_ITEM_PROBABILITY)) { has_special_item = true; }

			var rand = irandom(3);
			switch rand {
				case 0: { item_type = obj_rosary; array_push(global.controller.rooms_with_rosary, self); break; }
				case 1: { item_type = obj_map; array_push(global.controller.rooms_with_map, self); break; }
				case 2: { item_type = obj_sword; array_push(global.controller.rooms_with_sword, self); break; }
				default: { item_type = obj_torch; array_push(global.controller.rooms_with_torch, self); break; }
			}
		}
		if (irandom(100) < global.controller.HAS_KEY_PROBABILITY && item_type == noone) { has_key = true; array_push(global.controller.rooms_with_key, self); }
		if (irandom(100) < global.controller.HAS_COLLECTABLE_PROBABILITY) { has_collectables = true; array_push(global.controller.rooms_with_collectables, self); }
	
		// Randomly determine the number of exits this room should have based on probability weighting
		var target_number_of_exits = 0;
		var rand = irandom(100)-array_length(global.controller.game_rooms); // subtract number of rooms in order to drive generation toward an end eventually
		do {
			rand -= global.controller.NUMBER_OF_EXITS_PROBABILITIES[target_number_of_exits];
		    target_number_of_exits += 1;
		}
		until (rand <= 0);
	
		// Take care of exits that must exist based on adjacent rooms and decrement number of exits accordingly
		for (var i = 0; i < 4; i++) {
		    if (adj_rooms[i]) { 
		        // If this room has an adjoining room in this direction, make sure it also has an exit in that
		        // direction. Then, link the rooms so they each have the other listed as an adj_room.
		        exits[i] = true; 
		        link_adjoining_room(adj_rooms[i], i) 
		    }
		    else if (exits[i]) {
		        // Create adjoining room if this room has an exit in that direction but not an adjoining room.
		        // This really only happens for the first room, where exits are set to true by the controller.
		        create_adjoining_room(i, list_of_rooms);
		    }
		}

		// Generate some number of random additional exits
		while (count_exits() < target_number_of_exits) {
		    add_random_exit(false, list_of_rooms);
		}

	}
	
	/// @function								create_locked_exit(dir);
	/// @param		{direction}		dir			The directional exit of the room to create a locked exit in.
	function create_locked_exit(dir) {
		var new_exit = new RoomExit(self, dir);
	
		new_exit.room_1.locked_exits[new_exit.room_1_dir] = new_exit;
		new_exit.room_2.locked_exits[new_exit.room_2_dir] = new_exit;
	
		return new_exit;
	}
	
	/// @function								create_adjoining_room(dir, list_of_rooms);
	///	@param		{direction}	dir				The direction from this room in which to create the adjoining room
	/// @param		{index}		list_of_rooms	The list of all created rooms
	function create_adjoining_room(dir, list_of_rooms) {
		var x_offset = 0
		var y_offset = 0;

		switch(dir)
		{
		    case directions.up: { y_offset = -16; break; }
		    case directions.right: { x_offset = 16; break; }
		    case directions.down: { y_offset = 16; break; }
		    case directions.left: { x_offset = -16; break; }
		}

		var new_room = new GameRoom(virtual_x+x_offset, virtual_y+y_offset);
		array_push(global.controller.game_rooms, new_room);
		link_adjoining_room(new_room, dir);
		array_push(list_of_rooms, new_room);
	}
	
	/// @function								link_adjoining_room(adjoining_room, dir);
	/// @param		{index}		adjoining_room	The adjacent room to link to this one via a new exit
	/// @param		{direction}	dir				The direction from this room in which the adjoining room lies
	function link_adjoining_room(adjoining_room, dir) {
		adj_rooms[dir] = adjoining_room;
		exits[dir] = true;
	
		with adjoining_room {
		    adj_rooms[opposite_dir(dir)] = other;
		    exits[opposite_dir(dir)] = true;
		}
	}
	
	/// @function									add_random_exit(must_create_new, list_of_rooms);
	/// @param		{boolean}	must_create_new		Whether or not an exit must be created as a result of this method
	/// @param		{index}		list_of_rooms		The list of all created rooms
	function add_random_exit(must_create_new, list_of_rooms) {
		// TODO: Add stair linkage to this function
		if (count_exits() > 3 || (must_create_new && count_adjacent_rooms() > 3)) { 
		    return false; 
		    // Impossible to create a new exit in this case. This method should not be called under
		    // These circumstances anyway, but this guard clause is here for protection.
		}

		// Randomly determine where the next exit position will be
		var next_exit_pos = irandom(3);
		do { next_exit_pos = (next_exit_pos+1) mod 4; }
		until (must_create_new && !get_adjacent_room(next_exit_pos) ||
		       !must_create_new && !exits[next_exit_pos])

		// Create an exit at this position, then either link to the adjacent room that is in
		// that direction or create a new room in that direction
		exits[next_exit_pos] = true;
		var existing_room = get_adjacent_room(next_exit_pos);
		if (existing_room) { link_adjoining_room(existing_room, next_exit_pos); }
		else { create_adjoining_room(next_exit_pos, list_of_rooms); }
	}

	/// @function								count_exits();
	function count_exits() {
		var number_of_exits = 0;

		for (var i = 0; i < 4; i++) {
		    if (exits[i]) { number_of_exits += 1; }
		}
		
		return number_of_exits;
	}

	/// @function								count_adjacent_rooms();
	function count_adjacent_rooms() {
		var number_of_rooms = 0;

		for (var i = 0; i < 4; i++) {
		    if (get_adjacent_room(i)) { number_of_rooms += 1; }
		}
	
		return number_of_rooms;
	}

	/// @function								calculate_distance_to_current(distance)
	/// @param		{real}	distance			The number of rooms away from this room the current room is
	function calculate_distance_to_current(distance) {
		if (distance < distance_to_current_room) { distance_to_current_room = distance; }
		for (var i = 0; i < 4; i++) {
		    if (adj_rooms[i]) {
		        if (distance+1 < adj_rooms[i].distance_to_current_room) with adj_rooms[i] { calculate_distance_to_current(distance+1); }
		    }
		}
	}

	/// @function								draw_room(x_pos, y_pos)
	/// @param		{real}	x_pos				The x position to draw this room at
	/// @param		{real}	y_pos				The y position to draw this room at
	function draw_room(x_pos, y_pos) {

		// Only draw the room if the room has been visited at least once, or game is in test mode
		var carried_map = get_carried_item_of_type(obj_map);
		var show_detailed_map = global.controller.TEST_MODE || carried_map;
		var show_collectables = global.controller.TEST_MODE || (carried_map && carried_map.special);
		if (show_detailed_map || visited) {
			// Set up colors to draw this room with
			var fade_amount = distance_to_current_room / global.controller.MAX_MAP_DRAW_DISTANCE;
			var blink_frame = global.controller.number_of_frames_since_game_began mod 12 <= 5;
			var bg_color = global.controller.bg_color;
			var white_color = merge_color(c_white, bg_color, fade_amount);
			var red_color = merge_color(c_red, bg_color, fade_amount);
		
			// Darken the colors of unvisited rooms on the map
			if (!visited) {
				white_color = merge_color(white_color, bg_color, 0.5);
				red_color = merge_color(red_color, bg_color, 0.5);
			}
		
		    // Draw Room on Map
			var room_color = lit ? red_color : white_color;
			var inverse_color = lit ? white_color : red_color;
		    if (global.controller.current_room == self && blink_frame) { room_color = bg_color; }
			draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.875, 0.875, 0, room_color, 1);

		    // Draw Room's Exits on Map
			for (var i = 0; i < 4; i++) {
				var x_offset = 0, y_offset = 0, x_size = 0.25, y_size = 0.25, exit_color = bg_color;
				if (show_detailed_map && blink_frame && locked_exits[i] && locked_exits[i].locked) { exit_color = red_color; }

				switch i {
					case 0: { y_offset = -8; y_size += 0.125; break; } 
					case 1: { x_offset = 8; x_size += 0.125; break; } 
					case 2: { y_offset = 8; y_size += 0.125; break; } 
					case 3: { x_offset = -8; x_size += 0.125; break; } 
				}

			    if (exits[i]) { draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, exit_color, 1); }
			}
		
		    // Draw Room's Stairs
			var stair_color = bg_color;
		    if (exits[4]) { draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.125, 0.125, 0, stair_color, 1); }
		
		    // Draw Room's Keys if game is in test mode
		    if (show_detailed_map && has_key) { 
				var x_offset = get_virtual_quadrant_x_pos(rotate)-virtual_x, y_offset = get_virtual_quadrant_y_pos(rotate)-virtual_y;
				var key_color = inverse_color;
				draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, 0.125, 0.125, 0, key_color, 1); 
			}
		
			// Draw collectables if the map is special
			var collectable_color = inverse_color;
		    if (show_collectables) { 
				if (blink_frame && has_collectables) {
					draw_sprite_ext(spr_collectable, 0, x_pos, y_pos, 1, 1, 0, collectable_color, 1); 
				}
				if (!blink_frame && stairs_spot_obj == obj_encased_heart) {
					draw_sprite_ext(spr_map_heart, 0, x_pos, y_pos, 1, 1, 0, collectable_color, 1); 
				}
				if (!blink_frame && stairs_spot_obj == obj_cross) {
					draw_sprite_ext(spr_map_cross, 0, x_pos, y_pos, 1, 1, 0, collectable_color, 1); 
				}
			}
    
		    // Draw distance information if testing
		    //if (global.controller.TEST_MODE) {
		    //    draw_set_color(c_lime);
		    //    draw_set_halign(fa_center);
		    //    draw_set_valign(fa_middle);
		    //    if (distance_to_current_room < 9999) { draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_current_room))); }
		    //}
		}

		// Mark the room as having been drawn, then draw each of its applicable neighbors
		drawn = true;
		if (distance_to_current_room < global.controller.MAX_MAP_DRAW_DISTANCE || game_has_been_lost() || game_has_been_won()) {
		  if (adj_rooms[0] && !adj_rooms[0].drawn && y_pos-16 >= 0) with adj_rooms[0] { draw_room(x_pos, y_pos-16); }
		  if (adj_rooms[1] && !adj_rooms[1].drawn && x_pos+16 <= room_width) with adj_rooms[1] { draw_room(x_pos+16, y_pos); }
		  if (adj_rooms[2] && !adj_rooms[2].drawn && y_pos+16 <= room_height) with adj_rooms[2] { draw_room(x_pos, y_pos+16); }
		  if (adj_rooms[3] && !adj_rooms[3].drawn && x_pos-16 >= 0) with adj_rooms[3] { draw_room(x_pos-16, y_pos); }
		  // if (adj_rooms[4] && !adj_rooms[4].drawn) with adj_rooms[4] { draw_room(x_pos+(virtual_x - adj_rooms[4].virtual_x), y_pos+(virtual_y - adj_rooms[4].virtual_y)); }
		}
	}
	
	/// @fucntion								get_adjacent_room(dir);
	/// @param		{direction}	dir				The direction from this room to the adjacent room to get
	function get_adjacent_room(dir) {
		var x_pos = 0;
		var y_pos = 0;

		switch (dir)
		{
		    case directions.up: { y_pos = -16; break; }
		    case directions.right: { x_pos = 16; break; }
		    case directions.down: { y_pos = 16; break; }
		    case directions.left: { x_pos = -16; break; }
		}

		// TODO: Make this work without having to traverse the whole array
		for (var i = 0; i < array_length(global.controller.game_rooms); i++) {
			var possible_match = global.controller.game_rooms[i];
			if (possible_match.virtual_x == virtual_x+x_pos && possible_match.virtual_y == virtual_y+y_pos) {
				return possible_match;
			}
		}
		return noone;
	}
	
	/// @function								get_room_from_room_lists();
	function get_room_from_room_lists() {
		var number_of_exits = count_exits()
		var rand1 = get_random_chance_out_of(2);
		var rand2 = get_random_chance_out_of(2);
		var room_list = noone;

		switch (number_of_exits) {
			case 0: 
				room_list = global.controller.rooms_with_no_exits; 
		        flip_horizontal = rand1; 
		        flip_vertical = rand2;
				rotate = irandom(3);
				break;
		    case 1:
				room_list = global.controller.rooms_with_one_exit;
				flip_horizontal = rand1;
				flip_vertical = false;
				for (var i = 0; i < 4; i+= 1) {
					if (exits[i]) { rotate = i; break; }
				}
				break;
			case 2:
				room_list = global.controller.rooms_with_two_perpendicular_exits; 
		        if (exits[0] && exits[2]) { flip_horizontal = rand1; flip_vertical = rand2; room_list = global.controller.rooms_with_two_opposite_exits; }
		        else if (exits[1] && exits[3]) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (get_random_chance_out_of(2)) ? 1 : 3; room_list = global.controller.rooms_with_two_opposite_exits; }
		        else if (exits[0] && exits[1]) { flip_horizontal = false; flip_vertical = false; }
		        else if (exits[0] && exits[3]) { flip_horizontal = true; flip_vertical = false; }
		        else if (exits[1] && exits[2]) { flip_horizontal = false; flip_vertical = true; }
		        else {  flip_horizontal = true; flip_vertical = true; }
				break;
		    case 3:
				room_list = global.controller.rooms_with_three_exits; 
				flip_horizontal = false;
				flip_vertical = rand1;
				for (var i = 0; i < 4; i+= 1) {
					if (!exits[i]) { rotate = (i+1 > 4) ? 0 : i+1; break; }
				}
				break;
		    case 4:
				room_list = global.controller.rooms_with_four_exits; 
		        flip_horizontal = rand1; 
		        flip_vertical = rand2;
				rotate = irandom(3);
				break;
		}
	
		return array_random_get(room_list);
	}
	
	/// @function									walk_through_room(visited_rooms, exits_to_walk_through);
	/// @param		{index} visited_rooms			The list of rooms that have been visited on this walk of the map.
	/// @param		{index} exits_to_walk_through	The list of exits that need to be walked through to finish this walk of the map.
	function walk_through_room(visited_rooms, exits_to_walk_through, entered_from) {
		// Add the exits that can be reached to the list of visited exits
		var visited_exit_count = 0;
		for (var i = 0; i <= 4; i += 1;) {
			if (array_contains(reachable_exits[entered_from], i)) { visited_exits[i] = true; }
			if (visited_exits[i]) { visited_exit_count += 1; }
		}
		if (visited_exit_count >= 4) { array_push(visited_rooms, self); }
		// Add each of this room's existing, visited exits to the list of exits to try walking through at some point
		for (var i = 0; i <= 4; i += 1;) {
			if (exits[i] && adj_rooms[i] && visited_exits[i]) { array_push(exits_to_walk_through, [self, i]); }
		}
	}
	
	/// @function									leave_room()
	function initialize_from_room_reference() {
		var reference_instances = instances_for_room_reference(room_reference);
		for(var i = 0; i < array_length(reference_instances); i++) {
			var ref = reference_instances[i];
			instance_create_depth(ref.x, ref.y, 0, asset_get_index(ref.name));
		}
	}

	/// @function									leave_room()
	function leave_room() {
		instances = array_create(0);
		with (obj_game_object) { if (!persistent) { array_push(other.instances, self); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, self); } }
		for (var i = 0; i < array_length(instances); i++) { instance_deactivate_object(instances[i]); }
	}


	/// @function									enter_room()
	function enter_room() {
		global.controller.current_room = self;
		if (array_length(instances) == 0) { initialize_from_room_reference(); }
		else {
			for (var i = 0; i < array_length(instances); i++) {
				instance_activate_object(instances[i]);
			}
		}
	}
	
	/// @function									go_to_room()
	function go_to_room() {
		global.controller.current_room.leave_room();
		enter_room();
		with (global.controller) { 
			game_room_start();
			blackout = false;
			transition = noone;
		}
	}
	
	/// @function									get_reachable_exits()
	function get_reachable_exits() {
	switch (room_reference)
	{
		case rm_no_exits_1: {
			show_debug_message("Zero room generated");
			reachable_exits = [[], [], [], [], [4]];
			break;
		}
		default: {  
			var all_exits_available = [0,1,2,3,4];
			reachable_exits = array_create(5, all_exits_available);
			break;
		}
	}
}
}

/// @function									instances_for_room_reference()
function instances_for_room_reference(room_reference) {
	var filename = room_get_name(room_reference) + ".json";
	var file = file_text_open_read(filename);
	var file_content = file_text_read_string(file);
	var decoded_content = json_parse(file_content);
	file_text_close(file);
	return decoded_content;
}