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
	has_visited_exit_in_dir = [false, false, false, false, false];
	has_key = false;
	has_locked_chest = false;
	has_special_item = false;
	has_collectables = false;
	has_portcullis = false;
	
	drawn = false;
	visited = false;
	lit = false;
	misleading_room = false;
	stairs_spot_obj = -1;
	chest_obj = -1;
	
	// Room Content Values
	instances = array_create(0);
	solid_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	
	function calculate_distance_to_adjoining_rooms(start_distance) {
		if (start_distance < distance_to_start) { 
			distance_to_start = start_distance;
			for (var dir = directions.up; dir <= directions.stairs; dir++;) {
				var adj_room = get_adjoining_room(dir);
				adj_room.calculate_distance_to_adjoining_rooms(distance_to_start+1);
			}
		}
	}
	
	function has_visited_exit(dir) {
		return has_visited_exit_in_dir[dir];
	}
	
	function has_exit(dir) {
		return (exits[dir] != -1);
	}
	
	function get_cardinal_exits_count() {
		var exit_count = 0;
		for (var dir = directions.up; dir < directions.stairs; dir++;) { if (has_exit(dir)) { exit_count += 1; } }
		return exit_count;
	}
	
	function get_adjacent_room(dir) {
		if (dir >= directions.stairs) { return -1; }
		
		var game_rooms = global.controller.game_rooms, x_pos = virtual_x, y_pos = virtual_y, adj_room = -1;
		x_pos += get_dir_x_offset(dir);
		y_pos += get_dir_y_offset(dir);
				
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var game_room = game_rooms[i]
			if (game_room.virtual_x == x_pos && game_room.virtual_y == y_pos) { adj_room = game_room; break; }
		}
		return adj_room;
	}
	
	function get_adjoining_room(dir) {
		return (exits[dir] == -1) ? -1 : exits[dir].get_room_in_direction(dir);
	}
	
	function make_adjoining_room(new_room, dir) {
		exits[dir] = new RoomExit(self, new_room, dir);
		return exits[dir];
	}
	
	function create_adjoining_room() {
		// Get which adjoining directions are empty
		var empty_directions = array_create(0), game_rooms = global.controller.game_rooms;
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			if (get_adjoining_room(dir) == -1) { array_push(empty_directions, dir); }
		}
		if (array_length(empty_directions) == 0) { return -1; }
		
		// Choose a random empty adjoining direction
		array_shuffle(empty_directions);
		var chosen_dir = empty_directions[0], new_room = -1;
		if (chosen_dir == directions.stairs) {
			// Create room adjacent to any existing room in any open direction
			array_shuffle(game_rooms);
			for (var i = 0; i < array_length(game_rooms); i++) {
				var chosen_room = game_rooms[i];
				new_room = chosen_room.create_adjacent_room();
				if (new_room != -1) { break; }
			}
			if (new_room == -1) {
				// SHOULD NEVER REACH THIS POINT
				show_debug_message("ERROR: Couldn't create adjacent room to any room");
				return -1;
			}
		}
		else {
			// Create room adjacent to this room in the chosen direction
			new_room = create_room_in_dir(chosen_dir);
		}
		
		make_adjoining_room(new_room, chosen_dir);
		return new_room;
	}
	
	function create_adjacent_room() {
		// Get which adjacent directions are empty
		var empty_directions = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			if (get_adjacent_room(dir) == -1) { array_push(empty_directions, dir); }
		}
		if (array_length(empty_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle(empty_directions);
		var chosen_dir = empty_directions[0], 
		return create_room_in_dir(chosen_dir);
	}
	
	function create_room_in_dir(dir) {
		var x_pos = virtual_x + get_dir_x_offset(dir), y_pos = virtual_y + get_dir_y_offset(dir), new_room = new GameRoom(x_pos, y_pos);
		array_push(global.controller.game_rooms, new_room);
		return new_room;
	}
	
	function create_exit() {
		// Get which directions are not adjoining but do have an adjacent room
		var possible_directions = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			if (get_adjoining_room(dir) == -1) {
				var adjacent_room = get_adjacent_room(dir);
				if (adjacent_room != -1) { array_push(possible_directions, [dir, adjacent_room]); }
			}
		}
		if (array_length(possible_directions) == 0) { 
			return -1; 
		}
		
		// Choose a random possible direction and link that room
		array_shuffle(possible_directions);
		var chosen_possibility = possible_directions[0], chosen_dir = chosen_possibility[0], chosen_room = chosen_possibility[1]; 
		var new_exit = make_adjoining_room(chosen_room, chosen_dir);
		
		return new_exit;
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
	
	function add_key() {
		var controller = global.controller;
		if (has_key || controller.start_room == self || controller.heart_room == self) { return -1; }
		
		has_key = true;
		return true;
	}
	
	function add_collectables() {
		var controller = global.controller;
		if (has_collectables || controller.start_room == self || controller.heart_room == self) { return -1; }
		
		has_collectables = true;
		return true;
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
	
	/// @function								initialize_room(); // TODO: RENAME THIS
	function initialize_room() {
		var controller = global.controller;
		
		// Decide what features to randomly spawn
		if (stairs_spot_obj == -1 && get_random_chance_out_of(CHEST_PROBABILITY)) //{ set_up_room_chest(); }
		if (get_random_chance_out_of(COLLECTABLE_PROBABILITY)) { has_collectables = true; array_push(controller.rooms_with_collectables, self); }
		if (get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { has_portcullis = true; }
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
				if (show_detailed_map && !blink_frame && exits[dir] != -1 && exits[dir].has_lock) { exit_color = red_color; }

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

		// Mark the room as having been drawn, then draw each of its applicable neighbors
		drawn = true;
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			var adj_room = get_adjoining_room(dir);
			if (adj_room != -1 && !adj_room.drawn) {
				var new_x_pos = x_pos + (16*get_dir_x_offset(dir)), new_y_pos = y_pos + (16*get_dir_y_offset(dir));
				if (dir == directions.stairs) {
					new_x_pos = x_pos + (16 * (adj_room.virtual_x - virtual_x));
					new_y_pos = y_pos + (16 * (adj_room.virtual_y - virtual_y));
				}
				
				//if (new_x_pos > 0 && new_x_pos < room_width && new_y_pos >= 32 && new_y_pos <= room_height-32) { adj_room.draw_room(new_x_pos, new_y_pos); }
				adj_room.draw_room(new_x_pos, new_y_pos);
			}
		}
	}
}

function create_game_map() {
	var target_rooms = MINIMUM_NUMBER_OF_ROOMS + irandom(MAXIMUM_NUMBER_OF_ROOMS - MINIMUM_NUMBER_OF_ROOMS);
	game_rooms = array_create(0);
	array_push(game_rooms, new GameRoom(0, 0));
	
	// Add rooms to map until target is reached
	while (array_length(game_rooms) < target_rooms) {
		array_shuffle(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_adjoining_room_for = game_rooms[i];
			var new_room = room_to_create_adjoining_room_for.create_adjoining_room();
			if (new_room != -1) { break; }
		}
		if (new_room == -1) {
			// SHOULD NEVER REACH THIS POINT
			show_debug_message("ERROR: Couldn't create adjoining room for any room");
			return -1;
		}
	}
	
	// Add random additional exits to rooms
	/*
	var target_exits = (target_rooms * (20.0/9.0)), current_exits = target_rooms-1;
	while (current_exits < target_exits) {
		current_exits += 1;
		array_shuffle(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_exit_for = game_rooms[i];
			var new_exit = room_to_create_exit_for.create_exit();
			if (new_exit != -1) { break; }
		}		
		if (new_exit == -1) {
			// SHOULD NEVER REACH THIS POINT
			show_debug_message("ERROR: Couldn't create new exit for any room");
			return -1;
		}
	}
	*/
	
	// Choose random start room
	array_shuffle(game_rooms);
	start_room = game_rooms[0];
	
	// Calculate distance to start room for each other room
	start_room.calculate_distance_to_adjoining_rooms(0);
	
	// Choose random end_room from among the furthest away
	array_sort(game_rooms, function(elm1, elm2)
	{
		if (elm1.distance_to_start == elm2.distance_to_start) { return (get_coin_flip() ? 1 : -1); }
		else { return elm2.distance_to_start - elm1.distance_to_start; }
	});
	heart_room = game_rooms[0];

	// Add keys to rooms
	/*
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		// Add some locks
		var locks_added = game_rooms[pos].lock_exits(pos == 0);
		
		// Add some keys
		if (locks_added > 0) {
			var possible_key_rooms = array_create(0), keys_added = 0, new_key = -1;
			array_copy(possible_key_rooms, 0, game_rooms, pos+1, array_length(game_rooms)-(pos+1));
			while (keys_added < locks_added) {
				array_shuffle(possible_key_rooms);
				for (var i = 0; i < array_length(possible_key_rooms); i++;) {
					var room_to_add_key_to = possible_key_rooms[i];
					var new_key = room_to_add_key_to.add_key();
					if (new_key != -1) { break; }
				}
				if (new_key == -1) {
					// SHOULD NEVER REACH THIS POINT
					show_debug_message("ERROR: Couldn't create a key in any previous room");
					return -1;
				}
				keys_added += 1;
			}
		}
	}
	*/
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