function GameRoom(given_x, given_y) constructor {
	// Map Generation Values
	virtual_x = given_x;
	virtual_y = given_y;
	exits = [-1, -1, -1, -1, -1];
	distance_to_start = 9999;
	
	// Room Initialization Values
	flip_horizontal = false;
	flip_vertical = false;
	rotate = noone;
	
	// Room Start Values
	has_key = false;
	has_locked_chest = false;
	has_special_item = false;
	has_collectables = get_random_chance_out_of(COLLECTABLE_PROBABILITY);
	if (has_collectables) { array_push(global.controller.rooms_with_collectables, self); }
	
	visited = false;
	lit = false;
	misleading_room = get_random_chance_out_of(MISLEADING_ROOM_PROBABILITY);
	stairs_spot_obj = -1;
	chest_obj = -1;
	
	// Room Content Values
	instances = array_create(0);
	solid_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	
	function calculate_distance_to_connected_rooms(start_distance) {
		if (start_distance < distance_to_start) { 
			distance_to_start = start_distance;
			for (var dir = directions.up; dir <= directions.stairs; dir++;) {
				var connected_room = get_connected_room(dir);
				connected_room.calculate_distance_to_connected_rooms(distance_to_start+1);
			}
		}
	}
	
	function has_visited_exit(dir) {
		return (exits[dir] != -1 && exits[dir].visited);
	}
	
	function has_exit(dir) {
		return (exits[dir] != -1);
	}
	
	function get_cardinal_exits_count() {
		var exit_count = 0;
		for (var dir = directions.up; dir < directions.stairs; dir++;) { if (has_exit(dir)) { exit_count += 1; } }
		return exit_count;
	}
	
	function get_adjacent_room_directions(is_empty) {
		// Get which adjacent directions are empty
		var adjacent_room_directions = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			if ((get_adjacent_room(dir) == -1) == is_empty) { array_push(adjacent_room_directions, dir); }
		}
		return adjacent_room_directions;
	}
	
	function get_connected_room_directions(is_empty) {
		// Get which connected directions are not empty
		var connected_room_directions = array_create(0);
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			if ((get_connected_room(dir) == -1) == is_empty) { array_push(connected_room_directions, dir); }
		}
		return connected_room_directions;
	}
	
	function get_adjacent_room(dir) {
		// Only cardinal directions can have adjacent rooms
		if (dir >= directions.stairs) { return -1; }
		
		// Sort the game rooms in order of their x and y positions
		var game_rooms = global.controller.game_rooms, adj_room = -1;
		array_sort(game_rooms, function(elm1, elm2)
		{
			if (elm1.virtual_x == elm2.virtual_x) { return elm1.virtual_y - elm2.virtual_y; }
			else { return elm1.virtual_x - elm2.virtual_x; }
		});
		
		// Check the existing game rooms for the desired x and y positions
		var x_pos = virtual_x + get_dir_x_offset(dir), y_pos = virtual_y + get_dir_y_offset(dir), 
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var game_room = game_rooms[i];
			// Skip to rooms with the x_pos we are looking for
			if (game_room.virtual_x < x_pos) { continue; }
			else if (game_room.virtual_x > x_pos) { break; }
			// Skip to rooms with the y_pos we are looking for
			if (game_room.virtual_y < y_pos) { continue; }
			else if (game_room.virtual_y > y_pos) { break; }
			else { adj_room = game_room; break; }
		}
		return adj_room;
	}
	
	function get_connected_room(dir) {
		if (dir > directions.stairs) { return -1; }
		
		return ((exits[dir] == -1) ? -1 : exits[dir].get_connected_room(self));
	}
	
	function connect_room_with_new_exit(new_room, dir) {
		var new_exit = new RoomExit(self, new_room);
		exits[dir] = new_exit;
		new_room.exits[get_opposite_dir(dir)] = new_exit;
		return new_exit;
	}
	
	function create_connected_room() {
		// Determine which direction to create a connecting room in
		var chosen_room = self, connected_dir = directions.stairs, adj_dir = -1, game_rooms = global.controller.game_rooms;
		if (!has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			// Create room adjacent to any existing room in any open direction
			array_shuffle_ext(game_rooms);
			for (var i = 0; i < array_length(game_rooms); i++) {
				chosen_room = game_rooms[i];
				adj_dir = chosen_room.get_free_adjacent_room_direction();
				if (adj_dir != -1) { break; }
			}
			if (adj_dir == -1) {
				// SHOULD NEVER REACH THIS POINT
				show_debug_message("WARNING: Couldn't create adjacent room to any room");
				return -1;
			}
		}
		else { 
			adj_dir = get_free_adjacent_room_direction(); 
			connected_dir = adj_dir;
			if (adj_dir == -1) { return -1; }
		}
		
		// Create connecting room in the chosen direction
		var x_pos = chosen_room.virtual_x + get_dir_x_offset(adj_dir), y_pos = chosen_room.virtual_y + get_dir_y_offset(adj_dir), new_room = new GameRoom(x_pos, y_pos);
		array_push(game_rooms, new_room);
		
		connect_room_with_new_exit(new_room, connected_dir);
		
		return connected_dir;
	}
	
	function get_free_adjacent_room_direction() {
		// Get which adjacent directions are empty
		var empty_directions = get_adjacent_room_directions(true);
		if (array_length(empty_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle_ext(empty_directions);
		return empty_directions[0];
	}
	
	function connect_adjacent_room() {
		if (get_cardinal_exits_count() == 4) { return -1; }
		
		// Get which adjacent directions are empty
		var adjacent_room_directions = get_adjacent_room_directions(false), empty_connected_room_directions = get_connected_room_directions(true);
		var possible_directions = array_intersection(adjacent_room_directions, empty_connected_room_directions);
		if (array_length(possible_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle_ext(possible_directions);
		var chosen_dir = possible_directions[0], chosen_room = get_adjacent_room(chosen_dir);
		connect_room_with_new_exit(chosen_room, chosen_dir);
		return chosen_room;
	}
	
	function lock_exits(must_lock) {
		var locks_created = 0;
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var exit_in_dir = exits[dir];
			if (exit_in_dir != -1) {
				var should_create_lock = (must_lock || get_random_chance_out_of(LOCKED_DOOR_PROBABILITY));
				if (should_create_lock) { locks_created += exit_in_dir.lock(); }
			}
		}
		return locks_created;
	}
	
	/*
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
	*/
	
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
	
	function add_key() {
		var controller = global.controller;
		if (has_key || controller.start_room == self || controller.heart_room == self) { return false; }

		if (get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) { add_chest(true, obj_key); }
		has_key = true;
		array_push(controller.rooms_with_key, self);
		return true;
	}
	
	function add_collectables() {
		var controller = global.controller;
		if (has_collectables || controller.start_room == self) { return false; }
		
		has_collectables = true;
		array_push(controller.rooms_with_collectables, self);
		return true;
	}
	
	function add_portcullis() {
		if (exits[directions.stairs] != -1 || (has_key && has_collectables && stairs_spot_obj != -1)) { return false; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1 && (next_exit.has_lock || next_exit.has_illusion_walls)) { return false; }
		}
		
		if (!get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { return false; }
		
		// Add portcullis to this room's side of each rooms non-stairs exits
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_for_room(self, true); }
		}
		return true;
	}
	
	function remove_portcullis() {
		// Remove portcullis to this room's side of each rooms non-stairs exits
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_for_room(self, false); }
		}
	}
	
	
	function add_chest(must_spawn, given_item_obj) {
		if (!must_spawn || !get_random_chance_out_of(CHEST_PROBABILITY)) { return -1; }
		
		// Update room chest and item information
		var controller = global.controller;
		has_hidden_chest = (!lit && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		has_special_item = (array_length(controller.spawned_special_items) < SPECIAL_ITEM_LIMIT && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY));
		has_locked_chest = (!has_hidden_chest && (has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY)));
		var spawned_item_obj = (must_spawn) ? given_item_obj : get_random_item_obj(has_special_item, false);
		var spawned_item_array = (has_special_item) ? controller.spawned_special_items : controller.spawned_items;
		if (!must_spawn && !has_hidden_chest && !has_special_item && !has_locked_chest && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) { spawned_item_obj = obj_statue; }
		
		// Set up chest information to spawn
		stairs_spot_obj = (has_hidden_chest) ? obj_hidden_chest : obj_chest;
		chest_obj = spawned_item_obj;
		array_push(spawned_item_array, spawned_item_obj);
		if (has_locked_chest) { array_push(controller.rooms_with_locked_chest, self); }
		show_debug_message("SPAWNED" + ((has_special_item) ? " " : " RED ") + object_get_name(spawned_item_obj) + " " + string(spawned_item_obj));
		
		return spawned_item_obj;
	}

	/*
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
	*/
	
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

	/// @function									deactivate_room_instances()
	function deactivate_room_instances() {
		instances = array_create(0);
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
		for (var i = 0; i < array_length(instances); i++) { instance_deactivate_object(instances[i]); }
	}


	/// @function									activate_room_instances()
	function activate_room_instances() {
		if (array_length(instances) == 0) { initialize_from_room_reference(); }
		else {
			for (var i = 0; i < array_length(instances); i++) {
				instance_activate_object(instances[i]);
			}
		}
	}
	
	/// @function								set_room_reference();
	function set_room_reference() {
		var controller = global.controller, number_of_exits = get_cardinal_exits_count(), room_list_number_of_exits = number_of_exits, room_list = noone,
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
				if ((has_exit(directions.up) && has_exit(directions.down)) || 
					(has_exit(directions.right) && has_exit(directions.left))) { room_list = controller.rooms_with_two_opposite_exits; }
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
					if (has_exit(dir)) { rotate = dir; break; }
				}
				break;
			case 2:
			    if (has_exit(directions.up) && has_exit(directions.down)) { flip_horizontal = rand1; flip_vertical = rand2; }
			    else if (has_exit(directions.right) && has_exit(directions.left)) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (get_coin_flip()) ? directions.right : directions.left; }
			    else if (has_exit(directions.up) && has_exit(directions.right)) { flip_horizontal = false; flip_vertical = false; }
			    else if (has_exit(directions.up) && has_exit(directions.left)) { flip_horizontal = true; flip_vertical = false; }
			    else if (has_exit(directions.right) && has_exit(directions.down)) { flip_horizontal = false; flip_vertical = true; }
			    else if (has_exit(directions.left) && has_exit(directions.down)){  flip_horizontal = true; flip_vertical = true; }
				break;
			case 3:
				flip_horizontal = false;
				flip_vertical = rand1;
				for (var dir = directions.up; dir < directions.stairs; dir += 1) {
					if (!has_exit(dir)) { rotate = (dir+1 > 4) ? 0 : dir+1; break; }
				}
				break;
			case 4:
			    flip_horizontal = rand1; 
			    flip_vertical = rand2;
				rotate = get_random_carindal_dir();
				break;
		}
		
		room_reference = array_random_get(room_list);
	}
	
	/// @function					flip_room_contents_horizontally();
	function flip_room_contents_horizontally() {
		with obj_game_object {
		    if (object_index != obj_player) { x = room_width - x; }
		}
		with obj_placeholder {
			x = room_width - x;
		}
		with obj_exit_spot {
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
		with obj_exit_spot {
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
		with obj_exit_spot {
			if (direction_to_face == directions.right) { exit_dir = get_turn_right_dir(exit_dir); }
			else if (direction_to_face == directions.left) { exit_dir = get_turn_left_dir(exit_dir); }
			else if (direction_to_face == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	}
	
	/// @function								draw_room(x_pos, y_pos)
	/// @param		{real}	x_pos				The x position to draw this room at
	/// @param		{real}	y_pos				The y position to draw this room at
	function draw_room(x_pos, y_pos) {
		// Only draw the room if the given position is on screen
		if (x_pos < 0 || x_pos > room_width || y_pos <= 32 || y_pos >= room_height-32) { return false; }
		
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
				if (show_detailed_map && !blink_frame && exits[dir] != -1) {
					if (exits[dir].has_lock) { exit_color = red_color; }
					else if (exits[dir].has_portcullis_for_room(controller.current_room)) { exit_color = (is_test_mode_on) ? c_fuchsia : red_color; }
					else if (is_test_mode_on && exits[dir].has_illusion_walls) { exit_color = c_aqua; }
				}

				switch (dir) {
					case directions.up: { y_offset = -8; y_size += 0.125; break; } 
					case directions.right: { x_offset = 8; x_size += 0.125; break; } 
					case directions.down: { y_offset = 8; y_size += 0.125; break; } 
					case directions.left: { x_offset = -8; x_size += 0.125; break; } 
				}

			    if (has_exit(dir) && (has_visited_exit(dir) || show_detailed_map)) { draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, exit_color, 1); }
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
								if (show_detailed_map || has_visited_exit(directions.stairs)) { pos_color = white_color; break; }
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
		        draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_start)));
		    }
			
		}
		
		return true;
	}
}

function create_game_map() {
	var target_rooms = MINIMUM_NUMBER_OF_ROOMS + irandom(MAXIMUM_NUMBER_OF_ROOMS - MINIMUM_NUMBER_OF_ROOMS), created_cardinal_exits = 0;
	game_rooms = array_create(0);
	array_push(game_rooms, new GameRoom(0, 0));
	
	// Add rooms to map until target is reached
	while (array_length(game_rooms) < target_rooms) {
		var new_exit_dir = -1;
		array_shuffle_ext(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_connected_room_for = game_rooms[i];
			var new_exit_dir = room_to_create_connected_room_for.create_connected_room();
			if (new_exit_dir != -1) { 
				if (new_exit_dir != directions.stairs) { created_cardinal_exits += 1; }
				break; 
			}
		}
		if (new_exit_dir == -1) {
			// SHOULD NEVER REACH THIS POINT
			show_debug_message("WARNING: Couldn't create connected room for any room");
			return -1;
		}
	}
	
	// Add random additional cardinal exits to rooms
	while ((created_cardinal_exits*2)/(target_rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
		created_cardinal_exits += 1;
		array_shuffle_ext(game_rooms);
		var connected_room = -1;
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_exit_for = game_rooms[i];
			connected_room = room_to_create_exit_for.connect_adjacent_room();
			if (connected_room != -1) { break; }
		}		
		if (connected_room == -1) {
			// SHOULD NEVER REACH THIS POINT
			// TODO: Figure out if we care that this can happen
			//show_debug_message("WARNING: Couldn't create new exit for any room");
			//return -1;
			break;
		}
	}
	
	// Choose random start room
	array_shuffle_ext(game_rooms);
	start_room = game_rooms[0];
	
	// Calculate distance to start room for each other room
	start_room.calculate_distance_to_connected_rooms(0);
	
	// Choose random end_room from among the furthest away
	array_sort(game_rooms, function(elm1, elm2)
	{
		if (elm1.distance_to_start == elm2.distance_to_start) { return (get_coin_flip() ? 1 : -1); }
		else { return elm2.distance_to_start - elm1.distance_to_start; }
	});
	
	// Set up start and end rooms
	heart_room = game_rooms[0];
	heart_room.add_collectables();
	heart_room.stairs_spot_obj = obj_encased_heart;
	start_room.stairs_spot_obj = obj_cross;
	current_room = start_room;
}

function create_locks_and_keys() {
	// Add keys and locks to rooms
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		// Add some locks
		var this_room = game_rooms[pos], locks_added = this_room.lock_exits(this_room == heart_room);
		if (this_room.has_locked_chest) { locks_added += 1; }
		
		// Add some keys
		var possible_directions = array_shuffle(game_rooms[pos].get_connected_room_directions(false));
		array_push(possible_directions, directions.none);
		while (locks_added > 0 && array_length(possible_directions) > 0) {
			var next_dir = array_pop(possible_directions), var next_room = game_rooms[pos].get_connected_room(next_dir);
			if (next_dir == directions.none) { next_room = this_room; }
			if (next_room.has_key || next_room.distance_to_start > this_room.distance_to_start) { continue; }
			var new_key_added = next_room.add_key();
			if (new_key_added) { locks_added -= 1; }
		}
		if (locks_added > 0 && this_room.has_locked_chest) { locks_added -= 1; this_room.has_locked_chest = false; }
		if (locks_added > 0) {
			// SHOULD NEVER REACH THIS POINT
			show_debug_message("WARNING: Couldn't create new key for locked exit");
			return -1;
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