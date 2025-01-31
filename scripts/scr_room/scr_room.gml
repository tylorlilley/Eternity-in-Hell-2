function GameRoom(given_x, given_y) constructor {
	// Map Generation Values
	virtual_x = given_x;
	virtual_y = given_y;
	exits = [-1, -1, -1, -1, -1];
	distance_to_start = 9999;
	
	// Instance Positioning Values
	room_reference = -1;
	room_reference_difficulty = 0;
	old_room_reference_difficulty = 0;
	
	// Room Initialization Values
	visited = false;
	lit = false;
	stairs_spot_obj = -1;
	chest_obj = -1;
	
	// Room Start Values
	has_key = false;
	has_lanterns = false;
	has_hidden_chest = false;
	has_locked_chest = false;
	has_special_item = false;
	has_collectables = false;
	has_no_cardinal_exits = false;
	has_portcullis_button = false;
	has_misleading_exits = false;
	has_hall_of_mirrors = false;
	is_special_room = false;
	
	// Room Content Values
	instances = array_create(0);
	solid_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	solid_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];

	/// @function									assign_room_ref(must_have_lantern);
	/// @param		{bool} must_have_lantern	The instance id to add to the room map position
	function assign_room_ref(must_have_lantern) {
		if (room_reference != -1) { array_remove(global.controller.room_references, room_reference); }
		
		set_room_reference(must_have_lantern);
		update_game_room_initialize_values();
		update_game_room_difficulty_old();
		update_game_room_difficulty();
	}
	
	/// @function									update_game_room_initialize_values();
	function update_game_room_initialize_values() {
		is_special_room = array_contains(global.special_rooms, room_reference);
		has_lanterns = get_room_reference_object_count(obj_lantern) > 0;
		lit = (has_lanterns && get_random_chance_out_of(PRE_LIT_PROBABILITY));
		has_eyes = (get_room_reference_object_count(obj_eyes) > 0 || get_random_chance_out_of(EYES_PROBABILITY));
		has_all_cockroaches = (get_room_reference_object_count(obj_skeleton_spot) > 1 && get_random_chance_out_of(COCKROACH_ROOM_PROBABILITY));
		has_all_cultists = !has_all_cockroaches && (get_room_reference_object_count(obj_skeleton_spot) > 1 && get_random_chance_out_of(CULTIST_ROOM_PROBABILITY));
		has_phantom = (has_lanterns && !lit && !has_eyes && get_random_chance_out_of(PHANTOM_PROBABILITY));
		has_moving_collectable = get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);
		
		fountain_count = 0
		for (var i = 0; i < get_room_reference_object_count(obj_column); i++) {
			if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY)) { fountain_count += 1; }
		}
		
		initial_nose_count = 0;
		if (get_room_reference_object_count(obj_lava) > 0) {
			for (var i = 0; i < global.difficulty-1; i++;) {
				if (get_random_chance_out_of(NOSE_PROBABILITY)) { initial_nose_count += 1; }
			}
		}
		
		cockroach_count = 0;
		snake_count = 0;
		fast_skeleton_count = 0;
		fire_skeleton_count = 0;
		cultist_count = 0;
		skeleton_types = array_create(0);
		for (var i = 0; i < get_room_reference_object_count(obj_skeleton_spot); i++;) {
			var skeleton_type = obj_skeleton;
			if (has_eyes) { skeleton_type = obj_eyes; }
			else if (has_all_cockroaches) { skeleton_type = obj_cockroach; }
			else if (has_all_cultists) { skeleton_type = obj_cultist; }
			else {
				// Determine what to spawn in this skeleton spot
				var rand = irandom_range(1,100);
				switch (global.difficulty) {
					case difficulties.DO_NOT_USE: { break; }
					case difficulties.easy: {
						if rand <= 3 { skeleton_type = obj_cockroach; cockroach_count += 1; }
						break;
					}
					case difficulties.medium: {
						if rand <= 6 { skeleton_type = obj_cockroach; cockroach_count += 1; }
						else if rand <= 10 { skeleton_type = obj_snake; snake_count += 1; }
						else if rand <= 16 { skeleton_type = obj_fast_skeleton; fast_skeleton_count += 1; }
						else if rand <= 17 { skeleton_type = obj_cultist; cultist_count += 1; }
						break;
					}
					case difficulties.hard: {
						if rand <= 12 { skeleton_type = obj_cockroach; cockroach_count += 1; }
						else if rand <= 18 { skeleton_type = obj_snake; snake_count += 1; }
						else if rand <= 26 { skeleton_type = obj_fast_skeleton; fast_skeleton_count += 1; }
						else if rand <= 30 { skeleton_type = obj_cultist; cultist_count += 1; }
						else if rand <= 33 { skeleton_type = obj_fire_skeleton; fire_skeleton_count += 1; }
						break;
					}
					case difficulties.very_hard: {
						if rand <= 25 { skeleton_type = obj_cockroach; cockroach_count += 1; }
						else if rand <= 37 { skeleton_type = obj_snake; snake_count += 1; }
						else if rand <= 50 { skeleton_type = obj_fast_skeleton; fast_skeleton_count += 1; }
						else if rand <= 62 { skeleton_type = obj_cultist; cultist_count += 1; }
						else if rand <= 70 { skeleton_type = obj_fire_skeleton; fire_skeleton_count += 1; }
						break;
					}
				}
			}
			
			array_push(skeleton_types, skeleton_type);
		}
		
		initial_spider_count = 0;
		for (var i = 0; i < get_room_reference_object_count(obj_spider_spot); i++;) {
			if (get_random_chance_out_of(SPIDER_PROBABILITY)) { initial_spider_count += 1; }
		}
		
		var initial_mouths = get_room_reference_object_count(obj_mouth);
		initial_mouth_count = (initial_mouths * MOUTHS_PER_MOUTH) - initial_mouths;
		
		if (has_hall_of_mirrors) {
			mirror_directions = array_create(0);
			for (var i = 0; i < 4; i++) {
				array_push(mirror_directions, get_random_carindal_dir())
			}
			mirror_count = 0;
		}
	}
	
		/// @function									update_game_room_difficulty();
	function update_game_room_difficulty() {
		var has_bumper = get_room_reference_object_count(obj_bumper) > 0;
		var has_ears = get_room_reference_object_count(obj_ears) > 0;
		var has_gudetama = get_room_reference_object_count(obj_gudetama) > 0;
		
		room_reference_difficulty = 0;
	
		if (is_special_room) { room_reference_difficulty += 5; }
		if (has_phantom) { room_reference_difficulty += 2; }
		if (has_hall_of_mirrors) { room_reference_difficulty += 5; }
		if (has_bumper) { room_reference_difficulty += 1.25; }
		if (has_eyes) { room_reference_difficulty += 2.5; }
		if (has_all_cockroaches) { room_reference_difficulty += 0.25; }
		if (has_all_cultists) { room_reference_difficulty += 0.5; }
		if (has_ears) { room_reference_difficulty += 2.5; }
		if (has_gudetama) { room_reference_difficulty += 0.025; }
		
		room_reference_difficulty += fountain_count * 0.25;
		room_reference_difficulty += get_room_reference_object_count(obj_mouth) * 1;
		room_reference_difficulty += initial_nose_count * 0.75;
		room_reference_difficulty += (initial_spider_count > 0 ? 1.5 : 0) + initial_spider_count * 0.5;
		room_reference_difficulty += get_room_reference_object_count(obj_statue) * 0.325;
		room_reference_difficulty += get_room_reference_object_count(obj_fountain) * 0.325;
		room_reference_difficulty += (get_room_reference_object_count(obj_skeleton_spot) - fast_skeleton_count - snake_count - fire_skeleton_count - cultist_count - ((has_eyes) ? 1 : 0)) * 0.25;
		room_reference_difficulty += (get_room_reference_object_count(obj_snake) + snake_count) * 0.5
		room_reference_difficulty += fast_skeleton_count * 0.325;
		room_reference_difficulty += cultist_count * 0.325;
		room_reference_difficulty += fire_skeleton_count * 0.5;
		room_reference_difficulty += ((get_room_reference_object_count(obj_giant_worm_head) * 0.25) + (get_room_reference_object_count(obj_giant_worm_body) * 0.010));
	
		// Add a base increase if any enemies were present
		if (room_reference_difficulty != 0) { room_reference_difficulty += 0.25; }
		
		room_reference_difficulty += clamp(get_room_reference_object_count(obj_block_spot) * 0.01, 0, 0.25);
		room_reference_difficulty += clamp(get_room_reference_object_count(obj_lava) * 0.05, 0, 0.5);
		room_reference_difficulty += get_room_reference_object_count(obj_bones) * 0.010;
		
		if (has_hidden_chest) { room_reference_difficulty += 0.125; }
		if (!has_phantom && !has_hidden_chest && get_room_reference_object_count(obj_lantern) > 0) { room_reference_difficulty -= 0.125; }		
		if (has_lanterns && lit) { room_reference_difficulty -= 0.125; }
		if (has_locked_chest && !has_special_item) { room_reference_difficulty += 0.125; }
		if (has_no_cardinal_exits) { room_reference_difficulty += 0.125; }
		if (has_collectables) { room_reference_difficulty += 0.25; }
		if (has_misleading_exits) { room_reference_difficulty += 0.125; }
		if (chest_obj = obj_statue) { room_reference_difficulty += 0.325; }
		if (chest_obj = obj_fountain) { room_reference_difficulty += 0.325; }
		else if (!has_key && chest_obj != -1) { room_reference_difficulty -= 0.25; }
		if (has_special_item) { room_reference_difficulty -= 2; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) {
				if (next_exit.has_closed_portcullis_for_room(self)) { room_reference_difficulty += 0.325; }
				// These are all counted twice, once by each room the exit is connected to, and so should be halved
				if (next_exit.has_door) { room_reference_difficulty += 0.025; }
				if (next_exit.has_lock) { room_reference_difficulty += 0.125; }
				if (next_exit.has_illusion_walls) { room_reference_difficulty += 0.25; }
			}
		}
	}
	
	/// @function									update_game_room_difficulty_old();
	function update_game_room_difficulty_old() {
		var has_bumper = get_room_reference_object_count(obj_bumper) > 0;
		var has_ears = get_room_reference_object_count(obj_ears) > 0;
		var has_gudetama = get_room_reference_object_count(obj_gudetama) > 0;
		var has_echo = get_room_reference_object_count(obj_inverted_cross) > 0;
		
		old_room_reference_difficulty = 0;
		
		if (get_room_reference_object_count(obj_lantern) > 0) { old_room_reference_difficulty += 1; }
		if (has_bumper) { old_room_reference_difficulty += 1.5; }
		if (has_echo) { old_room_reference_difficulty += 5; }
		if (get_room_reference_object_count(obj_eyes) > 0) { old_room_reference_difficulty += 4; }
		if (has_ears) { old_room_reference_difficulty += 4; }
		if (has_gudetama) { old_room_reference_difficulty += 4; }
		
		old_room_reference_difficulty += get_room_reference_object_count(obj_mouth);
		old_room_reference_difficulty += floor(get_room_reference_object_count(obj_block_spot) * 0.08);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_lava) * 0.01);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_spider) * 1.2);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_bones) * 0.05);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_statue) * 0.25);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_skeleton_spot) * 0.33);
		old_room_reference_difficulty += ceil(get_room_reference_object_count(obj_snake) * 0.66);
		old_room_reference_difficulty += ceil((get_room_reference_object_count(obj_giant_worm_head) * 0.25) + (get_room_reference_object_count(obj_giant_worm_body) * 0.10));
	}
	
	/// @function									calculate_distance_to_connected_rooms(start_distance);
	/// @param		{real}	start_distance			The distance already traveled before this room was reached
	function calculate_distance_to_connected_rooms(start_distance) {
		if (start_distance < distance_to_start) { 
			distance_to_start = start_distance;
			for (var dir = directions.up; dir <= directions.stairs; dir++;) {
				var connected_room = get_connected_room(dir);
				connected_room.calculate_distance_to_connected_rooms(distance_to_start+1);
			}
		}
	}
	
	/// @function									has_visited_exit(dir);
	/// @param		{dir}	dir						The direction of the exit to check for visited status
	function has_visited_exit(dir) {
		return (exits[dir] != -1 && exits[dir].visited);
	}
	
	/// @function									has_exit(dir);
	/// @param		{dir}	dir						The direction of the exit to check for
	function has_exit(dir) {
		return (exits[dir] != -1);
	}
	
	/// @function									get_cardinal_exits_count();
	function get_cardinal_exits_count() {
		var exit_count = 0;
		for (var dir = directions.up; dir < directions.stairs; dir++;) { if (has_exit(dir)) { exit_count += 1; } }
		return exit_count;
	}
	
	/// @function									get_adjacent_room_directions();
	/// @param		{boolean} is_empty				Whether to return directions with adjacent rooms that do or don't exist
	function get_adjacent_room_directions(is_empty) {
		// Get which adjacent directions are empty
		var adjacent_room_directions = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var adj_room = get_adjacent_room(dir);
			if (adj_room != -1 && adj_room.has_no_cardinal_exits) { continue; }
			if ((adj_room == -1) == is_empty) { array_push(adjacent_room_directions, dir); }
		}
		return adjacent_room_directions;
	}
	
	/// @function									get_connected_room_directions();
	/// @param		{boolean} is_empty				Whether to return directions with connected rooms that do or don't exist
	function get_connected_room_directions(is_empty) {
		// Get which connected directions are not empty
		var connected_room_directions = array_create(0);
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			if ((get_connected_room(dir) == -1) == is_empty) { array_push(connected_room_directions, dir); }
		}
		return connected_room_directions;
	}
	
	/// @function									get_adjacent_room(dir);
	/// @param		{dir}	dir						The direction to check for an adjacent room in
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
	
	/// @function									get_connected_room(dir);
	/// @param		{dir}	dir						The direction to check for a connected room in
	function get_connected_room(dir) {
		if (dir > directions.stairs) { return -1; }
		
		return ((exits[dir] == -1) ? -1 : exits[dir].get_connected_room(self));
	}
	
	/// @function									connect_room_with_new_exit(new_room, dir);
	/// @param		{GameRoom}	new_room			The room to connect with this one
	/// @param		{dir}		dir					The direction to connect these rooms in
	function connect_room_with_new_exit(new_room, dir) {
		var new_exit = new RoomExit(self, new_room);
		exits[dir] = new_exit;
		new_room.exits[get_opposite_dir(dir)] = new_exit;
		if (dir == directions.stairs && get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY)) { new_room.has_no_cardinal_exits = true; }
		
		assign_room_ref(false);
		new_room.assign_room_ref(false);
		
		return new_exit;
	}
	
	/// @function									is_adjacent_room(tested_room);
	/// @param		{GameRoom}	tested_room			The room to test for adjacency
	function is_adjacent_room(tested_room) {
		var adjacent_room_directions = get_adjacent_room_directions(false);
		while (array_length(adjacent_room_directions) > 0) {
			var adj_dir = array_pop(adjacent_room_directions), adj_room = get_adjacent_room(adj_dir);
			if (adj_room == tested_room) { return true; }
		}
		return false;
	}
	
	/// @function									create_connected_room();
	function create_connected_room() {
		// Determine which direction to create a connecting room in
		var chosen_room = self, connected_dir = directions.stairs, adj_dir = -1, game_rooms = global.controller.game_rooms;
		// Sometimes connect rooms via stairs
		if (!has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			// Create room adjacent to any existing room in any open direction
			array_shuffle_ext(game_rooms);
			for (var i = 0; i < array_length(game_rooms); i++) {
				chosen_room = game_rooms[i];
				if (chosen_room == self || is_adjacent_room(chosen_room)) { continue; }
				
				adj_dir = chosen_room.get_free_adjacent_room_direction();
				if (adj_dir != -1) { break; }
			}
		}
		// Determine an adjacent room to connect via cardinal exit
		if (adj_dir == -1) { 
			chosen_room = self;
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
	
	
	/// @function									get_free_adjacent_room_direction();
	function get_free_adjacent_room_direction() {
		// Get which adjacent directions are empty
		var empty_directions = get_adjacent_room_directions(true);
		if (array_length(empty_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle_ext(empty_directions);
		return empty_directions[0];
	}
	
	/// @function									connect_adjacent_room();
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
	
	/// @function								reset_room_solid_path_grid();
	function reset_room_solid_path_grid() {
		mp_grid_clear_all(solid_path_grid);
		mp_grid_clear_all(solid_grid);
		with (obj_solid) { 
			mp_grid_add(other.solid_grid); 
			mp_path_grid_add(other.solid_path_grid); 
		}
	}
	
	/// @function								reset_room_lava_path_grid();
	function reset_room_lava_path_grid() {
		var room_lava_path_grid = lava_path_grid;
		
		mp_grid_clear_all(room_lava_path_grid);
		with (obj_solid) { mp_path_grid_add(room_lava_path_grid); }
		with (obj_lava_part) { mp_path_grid_add(room_lava_path_grid); }
	}
	
	/// @function								add_to_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to add to the room map position
	function add_to_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		//show_debug_message("added to room (" + string(virtual_x) + ", " + string(virtual_y) + ") at " + string(room_map_pos[0]) + ", " + string(room_map_pos[1]) + ": " + object_get_name(inst.object_index) + " - " + string(inst.id));
		array_push(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}

	/// @function								remove_from_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to remove from the room map position
	function remove_from_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		//show_debug_message("removed from room " + string(id) + "at" + string(room_map_pos[0]) + ", " + string(room_map_pos[1]) + ": " + object_get_name(inst.object_index) + " - " + string(inst.id));
		array_remove(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}
	
	/// @function								add_key();
	function add_key() {
		var controller = global.controller;
		if (has_key) { return false; }

		if (controller.heart_room != self && controller.start_room != self && chest_obj == -1 && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
			var new_item_type = get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY) ? obj_bomb : obj_key;
			add_chest(true, new_item_type); 
		}
		has_key = true;
		array_push(controller.rooms_with_key, self);
		return true;
	}
	
	/// @function								add_collectables();
	function add_collectables() {
		var controller = global.controller;
		if (has_collectables || controller.start_room == self) { return false; }
		
		has_collectables = true;
		array_push(controller.rooms_with_collectables, self);
		return true;
	}
	
	/// @function								add_illusion_walls();
	function add_illusion_walls() {
		var illusion_walls_added = false, controller = global.controller;
		if (controller.start_room == self) { return illusion_walls_added; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit == -1) { continue; }
			
			var next_room = next_exit.get_connected_room(self);
			if (next_room != controller.start_room && 
				!next_exit.has_door && 
				!next_exit.has_closed_portcullis_for_room(next_room) && 
				!next_exit.has_closed_portcullis_for_room(self) && 
				get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) {
					illusion_walls_added = true;
					next_exit.has_illusion_walls = true;
			}
		}
		
		return illusion_walls_added;
	}
	
	/// @function								add_portcullis();
	function add_portcullis() {
		if ((has_key && has_collectables && (stairs_spot_obj != -1 || exits[directions.stairs] != -1))) { return false; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1 && (next_exit.has_lock || next_exit.has_illusion_walls || next_exit.get_connected_room(self).has_portcullis_button)) { return false; }
		}
		
		if (!get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { return false; }
		
		// Add portcullis to this room's side of each rooms non-stairs exits
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_to_trigger_for_room(self, true); }
		}
		has_portcullis_button = true;
		return true;
	}
	
	/// @function								add_unlocked_doors();
	function add_unlocked_doors() {
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit == -1) { continue; }
			if (next_exit.has_lock || next_exit.has_illusion_walls || next_exit.get_connected_room(self).has_portcullis_button) { continue; }
			
			next_exit.has_door = get_random_chance_out_of(OPEN_DOOR_PROBABILITY*2);
		}
	}
	
	/// @function								remove_portcullis();
	function remove_portcullis() {
		// Remove portcullis to this room's side of each rooms non-stairs exits
		has_portcullis_button = false;
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_to_trigger_for_room(self, false); }
		}
	}
	
	/// @function								add_chest();
	function add_chest(must_spawn, given_item_obj) {
		if (!must_spawn && !get_random_chance_out_of(CHEST_PROBABILITY) && !is_special_room) { return -1; }
		
		// Update room chest and item information
		var controller = global.controller;
		has_hidden_chest = is_special_room || (!lit && has_lanterns && !has_phantom && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		has_special_item = is_special_room || (distance_to_start > 1 && array_length(controller.spawned_special_items) < SPECIAL_ITEM_LIMIT && (is_special_room || get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)));
		has_locked_chest = (!has_hidden_chest && (has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY)));
		var spawned_item_obj = (must_spawn) ? given_item_obj : get_random_item_obj(has_special_item, false);
		var spawned_item_array = (has_special_item) ? controller.spawned_special_items : controller.spawned_items;
		if (!must_spawn && !has_hidden_chest && !has_special_item && !has_locked_chest && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) { spawned_item_obj = (get_coin_flip()) ? obj_fountain : obj_statue; }
		
		// Set up chest information to spawn
		stairs_spot_obj = (has_hidden_chest) ? obj_hidden_chest : obj_chest;
		chest_obj = spawned_item_obj;
		array_push(spawned_item_array, spawned_item_obj);
		if (has_locked_chest) { array_push(controller.rooms_with_locked_chest, self); }
		show_debug_message("SPAWNED" + ((has_special_item) ? " RED " : " ") + object_get_name(spawned_item_obj) + " " + string(spawned_item_obj));
		
		return spawned_item_obj;
	}
	
	/// @function									initialize_from_room_reference();
	function initialize_from_room_reference() {
		var reference_instances = instances_for_room_reference(room_reference);
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

	/// @function									deactivate_room_instances();
	function deactivate_room_instances() {
		instances = array_create(0);
		with (obj_light_source) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
		for (var i = 0; i < array_length(instances); i++) { instance_deactivate_object(instances[i]); }
	}


	/// @function									activate_room_instances();
	function activate_room_instances() {
		if (array_length(instances) == 0) { initialize_from_room_reference(); }
		else {
			for (var i = 0; i < array_length(instances); i++) {
				instance_activate_object(instances[i]);
			}
		}
	}
	
	/// @function								set_room_reference(must_have_lantern);
	/// @param		{bool} must_have_lantern	The instance id to add to the room map position
	function set_room_reference(must_have_lantern) {
		var controller = global.controller, number_of_exits = get_cardinal_exits_count(), room_list_number_of_exits = number_of_exits, room_list = noone,
		var rand1 = get_coin_flip(), rand2 = get_coin_flip(), misleading_direction = (get_coin_flip()) ? 1 : -1;
		if (room_list_number_of_exits >= 4) { misleading_direction = -1; }
		else if (room_list_number_of_exits == 0) { misleading_direction = 1; }
		
		has_misleading_exits = get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)
		while(has_misleading_exits && (room_list_number_of_exits+misleading_direction) <= 4 && (room_list_number_of_exits+misleading_direction) >= 1) {
			has_misleading_exits = get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY);
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
		
		flip_horizontal = false;
		flip_vertical = false;
		rotate = noone;
		
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
		
		// Don't spawn duplicate room references unless necessary
		array_shuffle_ext(room_list);
		for (var i = 0; i < array_length(room_list); i++;) {
			var prev_room_reference = room_reference;
			room_reference = room_list[i];
			// Enforce Hall of Mirrors as room with all four exits available as regular exits
			if ((get_room_reference_object_count(obj_hall_of_mirrors) > 0) &&
				get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY) &&
				!has_misleading_exits &&
				has_exit(directions.up) && 
				has_exit(directions.down) && 
				has_exit(directions.left) && 
				has_exit(directions.right)) {
					has_hall_of_mirrors = true;
					is_special_room = true;	
					array_push(controller.spawned_special_rooms, room_reference);
				}
			else if (array_contains(global.special_rooms, room_reference) && 
					array_length(controller.spawned_special_rooms) < SPECIAL_ROOM_LIMIT &&
					get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY) &&
					get_room_reference_object_count(obj_hall_of_mirrors) == 0) {
				is_special_room = true;	
				array_push(controller.spawned_special_rooms, room_reference);
			}
			else {
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			if (must_have_lantern && get_room_reference_object_count(obj_lantern) == 0) { 
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			if (!array_contains(controller.room_references, room_reference)) { break; }
		}
		array_push(controller.room_references, room_reference);
		room_reference = rm_four_exits_23;// TODO: CHANGE ROOM REFERENCE HERE FOR TESTING
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
		if (x_pos < 0 || x_pos > room_width || y_pos < 0 || y_pos > room_height) { return false; }
		
		// Only draw the room if the room has been visited at least once, or game is in test mode
		var show_detailed_map = false, show_collectables = false, controller = global.controller, is_test_mode_on = global.is_test_mode;
		with (global.player) {
			show_detailed_map = (is_test_mode_on || is_carrying_item(obj_map));
			show_collectables = (is_test_mode_on || is_carrying_special_item(obj_map));
		}
		
		if (show_detailed_map || visited) {
			// Set up colors to draw this room with
			var fade_amount = 0; //distance_to_current_room / controller.MAX_MAP_DRAW_DISTANCE;
			var blink_frame = is_blink_frame();//modulo(global.game_manager.number_of_frames_since_game_began, 12) <= 5;
			var bg_color = global.bg_color;
			var white_color = merge_color(c_white, bg_color, fade_amount);
			var red_color = merge_color(get_game_color(), bg_color, fade_amount);
		
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
				if (!has_exit(dir)) { continue; }
				
				var exit_color = bg_color;
				if (!blink_frame) {
					if (exits[dir].has_lock) { exit_color = red_color; }
					else if (exits[dir].has_closed_portcullis_for_room(controller.current_room)) { exit_color = (is_test_mode_on) ? c_fuchsia : red_color; }
					else if (exits[dir].has_illusion_walls) { exit_color = (is_test_mode_on) ? c_teal : bg_color; }
				}

				var x_offset = 0, y_offset = 0, x_size = 0.25, y_size = 0.25;
				switch (dir) {
					case directions.up: { y_offset = -8; y_size += 0.125; break; } 
					case directions.right: { x_offset = 8; x_size += 0.125; break; } 
					case directions.down: { y_offset = 8; y_size += 0.125; break; } 
					case directions.left: { x_offset = -8; x_size += 0.125; break; } 
				}

			    if (has_visited_exit(dir) || show_detailed_map) { draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, exit_color, 1); }
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
								if (show_collectables) { pos_color = white_color; pos_sprite = spr_map_cross; pos_scale = 1; continue; }
							}
							else if (room_map_obj == obj_encased_heart || room_map_obj == obj_heart) {
								if (show_collectables) { 
									pos_image = (is_thump_frame()) ? 1 : 0;
									pos_color = inverse_color; 
									pos_sprite = spr_map_heart; 
									pos_scale = 1; 
									continue;
								}
							}
							else if (pos_sprite == spr_box) {
								if (room_map_obj == obj_stairs) {
									if (show_detailed_map || has_visited_exit(directions.stairs)) { pos_color = white_color; continue; }
								}
								else if (room_map_obj == obj_hole) { pos_color = white_color; continue; }
								else if (is_test_mode_on && has_locked_chest && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) { pos_color = c_aqua; continue; }
								else if (is_test_mode_on && has_key && ((chest_obj == obj_key && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) || room_map_obj == obj_key)) { pos_color = c_lime; continue; }
								else if (is_test_mode_on && has_hidden_chest && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) { pos_color = c_yellow; continue; }
								else if (pos_color == -1 && show_detailed_map && (show_collectables || room_map_obj != obj_hidden_chest)) { pos_color = inverse_color; }
							}
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
			
			// Draw difficulty information if testing
		    if (is_test_mode_on && keyboard_check(vk_f2)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(x_pos, y_pos, string_hash_to_newline(string(room_reference_difficulty)));
		    }
			
		}
		
		return true;
	}
}

function create_game_map() {
	var created_cardinal_exits = 0, target_rooms = MINIMUM_NUMBER_OF_ROOMS;// + irandom(MAXIMUM_NUMBER_OF_ROOMS - MINIMUM_NUMBER_OF_ROOMS);
	
	// Set up initial game room and game rooms array
	spawned_special_rooms = array_create(0);
	game_rooms = array_create(0);
	var initial_room = new GameRoom(0, 0);
	initial_room.assign_room_ref(false);
	array_push(game_rooms, initial_room);
	
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
	start_room = -1;
	for(var i = 0; i < array_length(game_rooms); i++) {
		var next_room = game_rooms[i];
		if (!next_room.has_exit(directions.stairs) && (global.is_test_mode || !next_room.is_special_room)) { 
			start_room = next_room; break; 
		}
	}
	if (start_room == -1) {
		// SHOULD NEVER REACH THIS POINT
		show_debug_message("WARNING: Couldn't pick a start room because all rooms had stairs");
		return -1;
	}
	
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

/// @function									add_rooms_to_reach_target_difficulty();
function add_rooms_to_reach_target_difficulty() {
	var total_difficulty = 0, added_rooms = 0, target_difficulty = AVERAGE_ROOM_DIFFICULTY * MINIMUM_NUMBER_OF_ROOMS;
	for (var i = 0; i < array_length(game_rooms); i++;) { total_difficulty += game_rooms[i].room_reference_difficulty; }
		
	while (total_difficulty < target_difficulty && array_length(game_rooms) < 32) {
		var new_exit_dir = -1;
		array_shuffle_ext(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_connected_room_for = game_rooms[i];
			var new_exit_dir = room_to_create_connected_room_for.create_connected_room();
			if (new_exit_dir != -1) { break; }
		}
		
		// Update difficulty tally
		total_difficulty= 0;
		added_rooms += 1;
		for (var i = 0; i < array_length(game_rooms); i++;) { total_difficulty += game_rooms[i].room_reference_difficulty; }
		
		if (new_exit_dir == -1) {
			// SHOULD NEVER REACH THIS POINT
			show_debug_message("WARNING: Couldn't create connected room for any room");
			return -1;
		}
	}
}

/// @function									get_earlier_room_without_key(target_dist);
/// @param		{real}	target_dist				The maximum distance from start of the keyless room to return
function get_earlier_room_without_key(target_dist) {
	var possible_rooms = array_create(0);
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		var next_room = game_rooms[pos];
		if (!next_room.has_key && next_room.distance_to_start < target_dist && (next_room != start_room || target_dist <= 1)) { array_push(possible_rooms, next_room); }
	}
	if (array_length(possible_rooms) == 0) { return -1; }
	
	return array_shuffle(possible_rooms)[0];
}

/// @function									create_locked_exits_and_keys();
function create_locked_exits_and_keys() {
	// Add keys and locks to rooms
	var exits_to_create_lock_and_key_for = array_create(0), attempted_exits = array_create(0), extra_locks = -1;
	
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		var next_room = game_rooms[pos], is_heart_room_exit = (next_room == heart_room), is_start_room_exit = (next_room == start_room);
		
		// Figure out which exits to lock
		var possible_directions = game_rooms[pos].get_connected_room_directions(false);
		for (var i = 0; i < array_length(possible_directions); i++;) {
			var dir = possible_directions[i], next_exit = next_room.exits[dir];
			
			// Skip stairs and previously visited exits since you can't lock those
			if (dir == directions.stairs || array_contains(attempted_exits, next_exit)) { continue; }
			array_push(attempted_exits, next_exit);
			
			// Check to see if this exit should be locked
			var connected_room = next_exit.get_connected_room(next_room);
			if (connected_room == heart_room) { is_heart_room_exit = true; }
			if (connected_room == start_room || next_room.has_hall_of_mirrors || connected_room.has_hall_of_mirrors) { is_start_room_exit = true; }
			if (!is_start_room_exit && (is_heart_room_exit || get_random_chance_out_of(LOCKED_DOOR_PROBABILITY/2))) {
				// Set this exit up to be locked
				if (is_heart_room_exit) { extra_locks += 1; }
				array_push(exits_to_create_lock_and_key_for, [next_room, dir]);
			}
		}
		
		// Figure out which chests are locked
		if (next_room.has_locked_chest && next_room.chest_obj != obj_key && next_room.chest_obj != obj_bomb) { // TODO: AFTER RED STAFF UPDATE && (!next_room.has_special_item || next_room.chest_obj != obj_staff))) { 
			array_push(exits_to_create_lock_and_key_for, [next_room, -1]); 
		}
	}
	if (extra_locks < 0) { extra_locks = 0; }
	
	// Sort the keys and locks to create by ascending distance from start room
	array_sort(exits_to_create_lock_and_key_for, function(elm1, elm2)
	{
		var dist1 = elm1[0].distance_to_start, dist2 = elm2[0].distance_to_start;
		return (dist1 == dist2) ? get_coin_flip() : dist1 - dist2;
	});
		
	// Create keys and lock exits
	var extra_lock_threshold = array_length(exits_to_create_lock_and_key_for)-extra_locks;
	for(var i = 0; i < array_length(exits_to_create_lock_and_key_for); i++;) {
		var just_lock = (i >= extra_lock_threshold), next_combo = exits_to_create_lock_and_key_for[i], room_to_lock = next_combo[0], lock_dir = next_combo[1];
		
		// If we are only locking or we have found a room to add a key to
		var key_room = get_earlier_room_without_key(room_to_lock.distance_to_start);
		if (just_lock || key_room != -1) {
			// Create key
			var new_key_created = (just_lock || key_room.add_key());
			if (new_key_created) {
				// Lock exit unless key is for a locked chest
				if (lock_dir != -1) { room_to_lock.exits[lock_dir].lock(); }
			}
			else { key_room = -1; }
		}
		
		// If key room couldn't be found or couldn't be locked
		if (key_room == -1) {
			// Unlock chest if key was for a locked chest
			if (lock_dir == -1) { room_to_lock.has_locked_chest = false; }
			// Skip locking any exit
			show_debug_message("WARNING: Couldn't add key for room at (" + string(room_to_lock.virtual_x) + ", " + string(room_to_lock.virtual_y) + ") with dist: " + string(room_to_lock.distance_to_start)); 
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