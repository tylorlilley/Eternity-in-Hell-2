function GameRoom(given_x, given_y) constructor {
	//room_reference = noone;
	instances = array_create(0);
	virtual_x = given_x;
	virtual_y = given_y;
	id = get_new_id();
	distance_to_start_room = 9999;

	// Initialize room state values
	visited = false;
	has_visited_exit_in_dir = [false, false, false, false, false];
	flip_horizontal = false;
	flip_vertical = false;
	rotate = noone;
	lit = false;

	// Room content values
	solid_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	has_key = false;
	has_locked_chest = false;
	has_special_item = false;
	has_collectables = false;
	has_portcullis = false;
	has_only_stairs_exit = false;
	misleading_room = false;
	stairs_spot_obj = -1;
	chest_obj = -1;

	// Initialize room topography information
	has_exit_in_dir = [false, false, false, false, false];
	exits = [noone, noone, noone, noone, noone];
	adj_rooms = [noone, noone, noone, noone, noone];
	
	function reset_room_solid_grid() {
		mp_grid_clear_all(solid_grid);
		mp_grid_add_instances(solid_grid, obj_solid, false);
	}
	
	function reset_room_lava_grid() {
		mp_grid_clear_all(lava_grid);
		mp_grid_add_instances(lava_grid, obj_lava, false);
	}
	
	/// @function								add_to_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to add to the room map position
	function add_to_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		//show_debug_message("added to room " + string(id) + "at" + string(room_map_pos[0]) + ", " + string(room_map_pos[1]) + ": " + object_get_name(inst.object_index) + " - " + string(inst.id));
		array_push(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}

	/// @function								remove_from_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to remove from the room map position
	function remove_from_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		//show_debug_message("removed from room " + string(id) + "at" + string(room_map_pos[0]) + ", " + string(room_map_pos[1]) + ": " + object_get_name(inst.object_index) + " - " + string(inst.id));
		array_remove(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}

	/// @function								get_room_map_position(inst);
	/// @param		{real} inst					The instance id to return a room map position for
	function get_room_map_position(inst) {
		// Set up room map positions
		var x_pos = 1, y_pos = 1;
		if (inst.y < room_height/2-16) { y_pos = 0; }
		else if (inst.y > room_height/2+16) { y_pos = 2; }
		if (inst.x < room_width/2-16) { x_pos = 0; }
		else if (inst.x > room_width/2+16) { x_pos = 2; }
	
		return [x_pos, y_pos]
	}
	
	/// @function								initialize_room(list_of_rooms);
	/// @param	{index}	list_of_rooms			The list of available rooms
	function initialize_room(list_of_rooms) {
		// Randomly decide if room will have collectables, stairs, keys, items, etc
		var controller = global.controller;
		
		// Decide what to spawn in stairs_spot
		if (has_only_stairs_exit || get_random_chance_out_of(STAIRS_PROBABILITY)) { set_up_room_stairs(list_of_rooms); }
		else if (get_random_chance_out_of(CHEST_PROBABILITY)) { set_up_room_chest(); }
		
		// Decide what to spawn in collectables spots
		if (has_only_stairs_exit || get_random_chance_out_of(COLLECTABLE_PROBABILITY)) { has_collectables = true; array_push(controller.rooms_with_collectables, self); }
		if (get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { has_portcullis = true; }
	
		// Take care of exits that must exist based on adjacent rooms and decrement number of exits accordingly
		for (var dir = directions.up; dir < directions.stairs; dir++) {
		    if (adj_rooms[dir]) { 
		        // If this room has an adjoining room in this direction, make sure it also has an exit in that
		        // direction. Then, link the rooms so they each have the other listed as an adj_room.
				has_exit_in_dir[dir] = true;
				link_adjoining_room(adj_rooms[dir], dir);
		    }
		    else if (has_exit_in_dir[dir]) {
		        // Create adjoining room if this room has an exit in that direction but not an adjoining room.
		        create_adjoining_room(dir, list_of_rooms);
		    }
		}
		
		// Randomly determine the number of exits this room should have based on probability weighting
		var target_number_of_exits = irandom(NUMBER_OF_EXITS_PROBABILITY);
		if (target_number_of_exits == 0 || target_number_of_exits > 3) { target_number_of_exits = 2; }
		if (has_only_stairs_exit) { target_number_of_exits = 0; }
		
		while(array_length(controller.game_rooms) + target_number_of_exits > MINIMUM_NUMBER_OF_ROOMS) { target_number_of_exits -= 1; }

		// Generate some number of random additional exits
		while (get_exits_count() < target_number_of_exits) {
		    var new_exit_created = add_random_exit(false, list_of_rooms);
			if (!new_exit_created) { break; }
		}
	}
	
	/// @function								set_up_room_stairs();
	function set_up_room_stairs(list_of_rooms) {
		var controller = global.controller;
		has_exit_in_dir[4] = true; 
		stairs_spot_obj = obj_stairs;
		if (has_only_stairs_exit) { array_push(controller.rooms_with_only_stairs, self); }
		else {
			array_push(controller.rooms_with_stairs_and_exits, self);
			if (get_random_chance_out_of(NO_EXIT_ROOM_PROBABILITY)) {
				// Create room with only stairs
				var new_room = noone, start_pos = irandom(array_length(controller.game_rooms)-1);
				for (var pos = 0; pos < array_length(controller.game_rooms); pos++;) {
					var next_pos = (pos + start_pos) % array_length(controller.game_rooms);
					new_room = controller.game_rooms[next_pos].create_adjacent_exitless_room(list_of_rooms);
					if (new_room != noone) { break; }
				}
				if (new_room == noone) {		
					// Should never need to reach this clause
					show_debug_message("WARNING: no possible adjacent position found to create room with only stairs");
				}
			}
		}
	}
	
	/// @function								create_adjoining_room(list_of_rooms);
	/// @param		{index}		list_of_rooms	The list of all created rooms
	function create_adjacent_exitless_room(list_of_rooms) {
		var start_dir = get_random_carindal_dir(), possible_dir = -1;
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_dir = (start_dir + dir) % 4;
			if (get_adjacent_room(next_dir) == noone) { possible_dir = next_dir; break; }
		}
		if (possible_dir == -1) { return noone; }

		// An empty possible direction has been found
		var controller = global.controller, x_offset = 0, y_offset = 0, 
		switch(possible_dir)
		{
		    case directions.up: { y_offset = -16; break; }
		    case directions.right: { x_offset = 16; break; }
		    case directions.down: { y_offset = 16; break; }
		    case directions.left: { x_offset = -16; break; }
		}

		var new_room = new GameRoom(virtual_x+x_offset, virtual_y+y_offset);
		new_room.has_only_stairs_exit = true;
		array_push(controller.game_rooms, new_room);
		array_push(list_of_rooms, new_room);
		
		return new_room;
	}
	
	/// @function								remove_room_stairs();
	function remove_room_stairs() {
		var controller = global.controller;
		
		has_only_stairs_exit = false;
		has_exit_in_dir[4] = false; 
		stairs_spot_obj = -1;
		if (has_only_stairs_exit) { array_remove(controller.rooms_with_only_stairs, self); }
		else { array_remove(controller.rooms_with_stairs_and_exits, self); }
	}
	
	/// @function								set_up_room_chest();
	function set_up_room_chest() {
		var controller = global.controller;
		// Determine if spawning a special item
		if (array_length(controller.spawned_special_items) < SPECIAL_ITEM_LIMIT && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { 
			has_special_item = true;
			has_locked_chest = true;
			var spawned_item_obj = get_random_item_obj(true, true);
			show_debug_message("SPAWNED RED " + object_get_name(spawned_item_obj) + " " + string(spawned_item_obj));
			if (spawned_item_obj == obj_key) { 
				set_up_room_key(); 
			}
			else {
				array_push(controller.spawned_special_items, spawned_item_obj);
				chest_obj = spawned_item_obj;
			}
		}
		// Spawn a trap chest instead of an item
		else if (get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) { chest_obj = obj_statue; }
		// Leave chest object open to spawn non-special, non-key item later
		else {
			has_locked_chest = get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
			array_push(controller.rooms_with_item, self); 
		}
				
		stairs_spot_obj = obj_chest;
	}
	
	function remove_room_chest() {
		var controller = global.controller;
		array_remove(controller.rooms_with_item, self); 
		array_remove(controller.spawned_special_items, chest_obj);
		
		stairs_spot_obj = -1;
		chest_obj = -1;
		has_locked_chest = false;
		has_special_item = false;
	}
	
	/// @function								set_up_room_key();
	function set_up_room_key() {
		var controller = global.controller;
		if (has_special_item || (stairs_spot_obj == -1 && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY))) {
			stairs_spot_obj = obj_chest;
			chest_obj = obj_key;
			if (has_special_item) { array_push(controller.spawned_special_items, obj_key); }
		}
		has_key = true; 
		array_push(controller.rooms_with_key, self); 
	}
	
	/// @function								remove_room_key();
	function remove_room_key() {
		var controller = global.controller;
		if (chest_obj == obj_key && stairs_spot_obj == obj_chest) {
			stairs_spot_obj = -1;
			chest_obj = -1;
			if (has_special_item) { array_remove(controller.spawned_special_items, obj_key); }
		}
		has_key = false; 
		array_remove(controller.rooms_with_key, self); 
	}
	
	/// @function								create_exit_for(dir);
	/// @param		{direction}		dir			The directional exit of the room to create a an exit in
	function create_exit_for(dir) {
		var new_exit = new RoomExit(self, dir);
	
		new_exit.room_1.exits[new_exit.room_1_dir] = new_exit;
		new_exit.room_2.exits[new_exit.room_2_dir] = new_exit;
	
		return new_exit;
	}
	
	/// @function								create_locked_exit(dir);
	/// @param		{direction}		dir			The directional exit of the room to create a locked exit in.
	function create_locked_exit(dir) {
		var new_exit = create_exit_for(dir);
	
		new_exit.locked = true;
		new_exit.has_door = true;
	
		return new_exit;
	}
	
	/// @function								create_illusion_walls_exit(dir);
	/// @param		{direction}		dir			The directional exit of the room to create a locked exit in.
	function create_illusion_walls_exit(dir) {
		var new_exit = create_exit_for(dir);
	
		new_exit.illusion_walls = true;
	
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
		return new_room;
	}
	
	/// @function								link_adjoining_room(adjoining_room, dir);
	/// @param		{index}		adjoining_room	The adjacent room to link to this one via a new exit
	/// @param		{direction}	dir				The direction from this room in which the adjoining room lies
	function link_adjoining_room(adjoining_room, dir) {
		adj_rooms[dir] = adjoining_room;
	
		with adjoining_room {
		    adj_rooms[get_opposite_dir(dir)] = other;
		    has_exit_in_dir[get_opposite_dir(dir)] = true;
		}
	}
	
	/// @function									add_random_exit(must_create_new, list_of_rooms);
	/// @param		{boolean}	must_create_new		Whether or not an exit must be created as a result of this method
	/// @param		{index}		list_of_rooms		The list of all created rooms
	function add_random_exit(must_create_new, list_of_rooms) {
		/*
		if (get_exits_count() > 3 || (must_create_new && get_adjacent_rooms_count() > 3)) { 
		    return false; 
			// Should never need to reach this clause
			show_debug_message("WARNING: add random exit called but no possible exits to create.");
			reset_map_generation();
			exit;
		}
		*/
		
		// Randomly determine where the next exit position will be
		var possible_new_exit_dirs = get_possible_new_exits_dirs(must_create_new), new_exit_dir = -1;
		if (array_length(possible_new_exit_dirs) == 0) { return false; }
		var new_exit_dir = array_random_pop(possible_new_exit_dirs);

		// Create an exit at this position, then either link to the adjacent room that is in
		// that direction or create a new room in that direction
		has_exit_in_dir[new_exit_dir] = true;
		var existing_room = get_adjacent_room(new_exit_dir);
		if (existing_room == noone) { create_adjoining_room(new_exit_dir, list_of_rooms); }
		else { link_adjoining_room(existing_room, new_exit_dir); }
		return true;
	}

	/// @function								get_exits_count();
	function get_exits_count() {
		var number_of_exits = 0;

		for (var dir = directions.up; dir < directions.stairs; dir++) {
		    if (has_exit_in_dir[dir]) { number_of_exits += 1; }
		}
		
		return number_of_exits;
	}

	/// @function								get_adjacent_rooms_count();
	function get_adjacent_rooms_count() {
		var number_of_rooms = 0;

		for (var dir = directions.up; dir < directions.stairs; dir++) {
		    if (get_adjacent_room(dir)) { number_of_rooms += 1; }
		}
	
		return number_of_rooms;
	}
	
	/// @function									get_possible_new_exits_dirs(must_create_new);
	/// @param		{boolean}	must_create_new		Whether the possible exit must not have an existing adjacent_room or not
	function get_possible_new_exits_dirs(must_create_new) {
		var possible_new_exit_dirs = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var potential_room = get_adjacent_room(dir);
			if (must_create_new && potential_room == noone) { array_push(possible_new_exit_dirs, dir); }
			else if (!must_create_new && !has_exit_in_dir[dir] && potential_room == noone || !potential_room.has_only_stairs_exit) { array_push(possible_new_exit_dirs, dir); }
		}
		return possible_new_exit_dirs;
	}

	/// @function								calculate_distance_to_current_room(distance)
	/// @param		{real}	distance			The number of rooms away from this room the current room is
	/*
	function calculate_distance_to_current_room(distance) {
		if (distance < distance_to_current_room) { distance_to_current_room = distance; }
		for (var dir = directions.up; dir < directions.stairs; dir++) {
		    if (adj_rooms[dir]) {
		        if (distance+1 < adj_rooms[dir].distance_to_current_room) with adj_rooms[dir] { calculate_distance_to_current_room(distance+1); }
		    }
		}
	}
	*/

	/// @function								draw_room(x_pos, y_pos)
	/// @param		{real}	x_pos				The x position to draw this room at
	/// @param		{real}	y_pos				The y position to draw this room at
	function draw_room(x_pos, y_pos) {
		// Only draw the room if the room has been visited at least once, or game is in test mode
		var show_detailed_map = false, show_collectables = false, controller = global.controller, is_test_mode_on = global.is_test_mode;
		with (global.player) {
			show_detailed_map = (is_test_mode_on || is_carrying_item(obj_map));
			show_collectables = (is_test_mode_on || is_carrying_special_item(obj_map));
		}
		
		if (show_detailed_map || visited) {
			// Set up colors to draw this room with
			var fade_amount = 0; //distance_to_current_room / controller.MAX_MAP_DRAW_DISTANCE;
			var blink_frame = modulo(global.game_manager.number_of_frames_since_game_began, 12) <= 5;
			var bg_color = global.bg_color;
			var white_color = merge_color(c_white, bg_color, fade_amount);
			var red_color = merge_color(c_red, bg_color, fade_amount);
		
			// Darken the colors of unvisited rooms on the map
			if (!visited) {
				white_color = merge_color(white_color, bg_color, 0.66);
				red_color = merge_color(red_color, bg_color, 0.66);
			}
			
		    // Draw Room on Map
			var room_color = lit ? red_color : bg_color;
			var inverse_color = lit ? bg_color : red_color;
		    if (controller.current_room != self || !blink_frame) {
				draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.875, 0.875, 0, white_color, 1);
				draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.75, 0.75, 0, room_color, 1);
			}

		    // Draw Room's Exits on Map
			for (var dir = directions.up; dir < directions.stairs; dir++) {
				var x_offset = 0, y_offset = 0, x_size = 0.25, y_size = 0.25, exit_color = bg_color;
				if (show_detailed_map && !blink_frame && exits[dir] != noone && exits[dir].locked) { exit_color = red_color; }

				switch (dir) {
					case directions.up: { y_offset = -8; y_size += 0.125; break; } 
					case directions.right: { x_offset = 8; x_size += 0.125; break; } 
					case directions.down: { y_offset = 8; y_size += 0.125; break; } 
					case directions.left: { x_offset = -8; x_size += 0.125; break; } 
				}

			    if (has_exit_in_dir[dir] && (has_visited_exit_in_dir[dir] || show_detailed_map)) { draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, exit_color, 1); }
			}
			
			// Draw room's map position objects
			for (var yy = 0; yy < 3; yy++) {
				for (var xx = 0; xx < 3; xx++) {
					// Check if any map positions exist at this part of the map and draw them if so
					var room_map_pos_array = instances_at_map_positions[xx][yy];
					if (array_length(room_map_pos_array) > 0) {
						// Get color of instance to draw
						var pos_color = -1, pos_sprite = spr_box, pos_image = 0, pos_scale = 0.125;
						for (var i = 0; i < array_length(room_map_pos_array); i++) { 
							var room_map_obj = room_map_pos_array[i];
				

							if (room_map_obj == obj_cross) {
								if (show_collectables) { pos_color = white_color; pos_sprite = spr_map_cross; pos_scale = 1; break; }
							}
							else if (room_map_obj == obj_encased_heart || room_map_obj == obj_heart) {
								if (show_collectables) { 
									pos_image = (is_thump_frame()) ? 1 : 0;
									pos_color = inverse_color; 
									pos_sprite = spr_map_heart; 
									pos_scale = 1; 
									break;
								}
							}
							else if (room_map_obj == obj_stairs) {
								if (show_detailed_map || has_visited_exit_in_dir[directions.stairs]) { pos_color = white_color; break; }
							}
							else if (is_test_mode_on && has_locked_chest && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) { pos_color = c_aqua; break; }
							else if (is_test_mode_on && has_key && ((chest_obj == obj_key && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) || room_map_obj == obj_key)) { pos_color = c_lime; break; }
							else if (show_detailed_map) { pos_color = inverse_color; }
						}
						
						// Draw obj at pos
						if (pos_color != -1) {
							var x_offset = 0, y_offset = 0;
							if (xx == 0) { x_offset -= 3; }
							else if (xx == 2) { x_offset += 3; }
							if (yy == 0) { y_offset -= 3; }
							else if (yy == 2) { y_offset += 3; }
							draw_sprite_ext(pos_sprite, pos_image, x_pos+x_offset, y_pos+y_offset, pos_scale, pos_scale, 0, pos_color, 1); 
						}
					}
				}
			}
		
			// Draw collectables if the map is special
		    if (show_collectables && has_collectables && !blink_frame) {
				draw_sprite_ext(spr_collectable, 0, x_pos, y_pos, 1, 1, 0, white_color, 1); 
			}
    
		    // Draw distance information if testing
		    if (is_test_mode_on && keyboard_check(vk_f1)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_start_room)));
		    }
			
		}

		// Mark the room as having been drawn, then draw each of its applicable neighbors
		drawn = true;
		//if (distance_to_current_room < controller.MAX_MAP_DRAW_DISTANCE || is_game_lost() || is_game_won()) { 
		if (adj_rooms[directions.up] && !adj_rooms[directions.up].drawn && y_pos-16 >= 0) { with adj_rooms[directions.up] { draw_room(x_pos, y_pos-16); } }
		if (adj_rooms[directions.right] && !adj_rooms[directions.right].drawn && x_pos+16 <= room_width) { with adj_rooms[directions.right] { draw_room(x_pos+16, y_pos); } }
		if (adj_rooms[directions.down] && !adj_rooms[directions.down].drawn && y_pos+16 <= room_height) { with adj_rooms[directions.down] { draw_room(x_pos, y_pos+16); } }
		if (adj_rooms[directions.left] && !adj_rooms[directions.left].drawn && x_pos-16 >= 0) { with adj_rooms[directions.left] { draw_room(x_pos-16, y_pos); } }
		if (adj_rooms[directions.stairs] && !adj_rooms[directions.stairs].drawn) {
			var stairs_room = adj_rooms[directions.stairs], other_x_pos = x_pos+(stairs_room.virtual_x - virtual_x), other_y_pos = y_pos+(stairs_room.virtual_y - virtual_y);
			with (stairs_room) { draw_room(other_x_pos, other_y_pos); }
		}
	}
	
	/// @fucntion								get_adjacent_room(dir);
	/// @param		{direction}	dir				The direction from this room to the adjacent room to get
	function get_adjacent_room(dir) {
		var x_pos = 0, y_pos = 0, controller = global.controller;

		switch (dir)
		{
		    case directions.up: { y_pos = -16; break; }
		    case directions.right: { x_pos = 16; break; }
		    case directions.down: { y_pos = 16; break; }
		    case directions.left: { x_pos = -16; break; }
		}

		// TODO: Make this work without having to traverse the whole array
		for (var i = 0; i < array_length(controller.game_rooms); i++) {
			var possible_match = controller.game_rooms[i];
			if (possible_match.virtual_x == virtual_x+x_pos && possible_match.virtual_y == virtual_y+y_pos) {
				return possible_match;
			}
		}
		return noone;
	}
	
	/// @function								get_room_from_room_lists();
	function get_room_from_room_lists() {
		var controller = global.controller, number_of_exits = get_exits_count(), room_list_number_of_exits = number_of_exits, room_list = noone,
		var rand1 = get_coin_flip(), rand2 = get_coin_flip(), misleading_chance = MISLEADING_ROOM_PROBABILITY, misleading_direction = (get_coin_flip()) ? 1 : -1;
		if (room_list_number_of_exits >= 4) { misleading_direction = -1; }
		else if (room_list_number_of_exits == 0) { misleading_direction = 1; misleading_chance= floor(misleading_chance/2); }
		
		while(get_random_chance_out_of(misleading_chance) && room_list_number_of_exits < 4 && room_list_number_of_exits > 1) {
			misleading_room = true;
			room_list_number_of_exits += misleading_direction;
		}
		
		switch(room_list_number_of_exits) {
			case 0: 
				room_list = controller.rooms_with_no_exits; 
				break;
			case 1: 
				room_list = controller.rooms_with_one_exit; 
				break;
			case 2: 
				room_list = controller.rooms_with_two_perpendicular_exits;
				if ((has_exit_in_dir[directions.up] && has_exit_in_dir[directions.down]) || 
					(has_exit_in_dir[directions.right] && has_exit_in_dir[directions.left])) { room_list = controller.rooms_with_two_opposite_exits; }
				break;
			case 3: 
				room_list = controller.rooms_with_three_exits; 
				break;
			case 4: 
				room_list = controller.rooms_with_four_exits; 
				break;
		}

		var 
		switch (number_of_exits) {
			case 0: 
		        flip_horizontal = rand1; 
		        flip_vertical = rand2;
				rotate = get_random_carindal_dir();
				break;
		    case 1:
				flip_horizontal = rand1;
				flip_vertical = false;
				for (var dir = directions.up; dir < directions.stairs; dir += 1) {
					if (has_exit_in_dir[dir]) { rotate = dir; break; }
				}
				break;
			case 2:
		        if (has_exit_in_dir[directions.up] && has_exit_in_dir[directions.down]) { flip_horizontal = rand1; flip_vertical = rand2; }
		        else if (has_exit_in_dir[directions.right] && has_exit_in_dir[directions.left]) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (get_coin_flip()) ? directions.right : directions.left; }
		        else if (has_exit_in_dir[directions.up] && has_exit_in_dir[directions.right]) { flip_horizontal = false; flip_vertical = false; }
		        else if (has_exit_in_dir[directions.up] && has_exit_in_dir[directions.left]) { flip_horizontal = true; flip_vertical = false; }
		        else if (has_exit_in_dir[directions.right] && has_exit_in_dir[directions.down]) { flip_horizontal = false; flip_vertical = true; }
		        else if (has_exit_in_dir[directions.left] && has_exit_in_dir[directions.down]){  flip_horizontal = true; flip_vertical = true; }
				break;
		    case 3:
				flip_horizontal = false;
				flip_vertical = rand1;
				for (var dir = directions.up; dir < directions.stairs; dir += 1) {
					if (!has_exit_in_dir[dir]) { rotate = (dir+1 > 4) ? 0 : dir+1; break; }
				}
				break;
		    case 4:
		        flip_horizontal = rand1; 
		        flip_vertical = rand2;
				rotate = get_random_carindal_dir();
				break;
		}
		
		// Create Illusion Wall Exits
		for (var dir = directions.up; dir < directions.stairs; dir++) {
			if (has_exit_in_dir[dir] && other.current_room.exits[dir] == noone && get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) {
				exits[dir] = create_illusion_walls_exit(dir);    
			}
		}
		
		var ref = array_random_get(room_list);
		return ref;
	}
	
	/// @function									initialize_from_room_reference()
	function initialize_from_room_reference() {
		var reference_instances = instances_for_room_reference(room_reference); // CHANGE ROOM REFERENCE HERE FOR TESTING
		for(var i = 0; i < array_length(reference_instances); i++) {
			var ref = reference_instances[i];
			instance_create(ref.x, ref.y, asset_get_index(ref.name));
		}
	}
	
	/// @function								get_room_reference_object_count();
	/// @param		{int} obj					The object index to check for the presence of
	function get_room_reference_object_count(obj) {
		var reference_instances = instances_for_room_reference(room_reference);
		var count = 0;
		for(var i = 0; i < array_length(reference_instances); i++) {
			var ref = reference_instances[i];
			if (asset_get_index(ref.name) == obj) { count += 1; }
		}
		return count;
	}

	/// @function									leave_room()
	function leave_room() {
		instances = array_create(0);
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
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
	/// @param		{bool}	visited_by_player		Whether it is the player or the game visiting this room
	function go_to_room(visited_by_player) {
		var controller = global.controller;
		
		if (visited_by_player) { 
			mark_exit_visited(); 
			game_room_end();
		}
		controller.current_room.leave_room();
		enter_room();
		
		with (controller) {
			if (!visited_by_player) { game_room_initialize(); }
			else { game_room_start(); }
			blackout = false;
			transition = directions.none;
			transitioned_from = noone;
		}
	}
	
	/// @function									mark_exit_visited()
	function mark_exit_visited() {
		var controller = global.controller;
		var exit_dir = controller.transition, other_room = controller.current_room;
		if (exit_dir == directions.stairs) {
			if (controller.transitioned_from.object_index == obj_stairs) {
				other_room.has_visited_exit_in_dir[directions.stairs] = true;
				has_visited_exit_in_dir[directions.stairs] = true;
			}
		}
		else if (exit_dir != directions.respawn) {
			other_room.has_visited_exit_in_dir[exit_dir] = true;
			has_visited_exit_in_dir[get_opposite_dir(exit_dir)] = true;
		}
	}
}

/// @function									instances_for_room_reference()
function instances_for_room_reference(room_reference) {
	var filename = room_get_name(room_reference) + ".json";
	var file = file_text_open_read(filename);
	var file_difficulty_content = file_text_read_string(file);
	file_text_readln(file);
	var file_instances_content = file_text_read_string(file);
	var decoded_content = json_parse(file_instances_content);          
	file_text_close(file);
	return decoded_content;
}

/// @function								difficulty_for_room_reference();
function difficulty_for_room_reference(room_reference) {
	var filename = room_get_name(room_reference) + ".json";
	var file = file_text_open_read(filename);
	if (file == -1) { return 0; }
	
	var file_difficulty_content = file_text_read_string(file);
	file_text_readln(file);
	var decoded_content = string_digits(file_difficulty_content);          
	file_text_close(file);
	return decoded_content;
}


/// @function					flip_room_contents_horizontally();
function flip_room_contents_horizontally() {
	with obj_game_object {
	    if (object_index != obj_player) { x = room_width - x; }
	}
	with obj_placeholder {
		x = room_width - x;
	}
	with obj_exit_placeholder {
		if (exit_dir == directions.right || exit_dir == directions.left) { exit_dir = get_opposite_dir(exit_dir); }
	}
}

/// @function				flip_room_contents_vertically();
function flip_room_contents_vertically() {
	with obj_game_object {
	    if (object_index != obj_player) { y = room_height - y; }
	}
	with obj_placeholder {
		y = room_height - y;
	}
	with obj_exit_placeholder {
		if (exit_dir == directions.up || exit_dir == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
	}
}

/// @function									rotate_room_contents_around_room_center(direction_to_face);
/// @param		{direction}	direction_to_face	The direction in which the room should face once rotated
function rotate_room_contents_around_room_center(direction_to_face) {
	var angle = direction_to_face * 90;
	
	with obj_game_object {
	    if (object_index != obj_player) { 
			image_angle = 0;
			var x_prev = x - room_width/2;
			var y_prev = y - room_height/2;
			
			x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
			y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
			if (!place_snapped(4, 4)) { move_snap(4, 4); }
		}
	}
	with obj_placeholder {
		image_angle = 0;
		var x_prev = x - room_width/2;
		var y_prev = y - room_height/2;
			
		x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
		y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
		if (!place_snapped(4, 4)) { move_snap(4, 4); }
	}
	with obj_exit_placeholder {
		if (direction_to_face == directions.right) { exit_dir = get_turn_right_dir(exit_dir); }
		else if (direction_to_face == directions.left) { exit_dir = get_turn_left_dir(exit_dir); }
		else if (direction_to_face == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
	}
}

function mp_grid_add(grid) {
	mp_grid_add_instances(grid, self, false);
}

function mp_grid_remove(grid) {
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		mp_grid_clear_cell(grid, x_pos/GRID_SIZE, y_pos/GRID_SIZE);
	}
}