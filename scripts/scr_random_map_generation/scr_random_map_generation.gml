function MapWalker(dir) constructor {
	// Trip History
	visited_rooms = array_create(0);
	keyless_visited_rooms = array_create(0);
	encountered_locks = array_create(0);
	unlocked_exits = array_create(0);
	unlocked_chests = array_create(0);
	
	// Trip Present
	current_room = noone;
	keys_found = 0;
	keys_remaining = 0;
	has_found_special_key = false;
	walk_distance = 0;
	min_key_distance = 9999;
	start_dir = dir;
	
	function collect_key() {
		if (walk_distance < min_key_distance) { min_key_distance = walk_distance; }
		keys_remaining += 1; 
		keys_found += 1;
	}
	
	function spend_key() {
		keys_remaining -= 1;
		if (keys_remaining == 0) { min_key_distance = 9999; }
	}
	
	function visit_room(new_room) {
		if (walk_distance < new_room.distance_to_start_room) { new_room.distance_to_start_room = walk_distance; }
		if (array_contains(visited_rooms, new_room)) { return false; }
		
		// Update trip history
		walk_distance += 1;
		array_push(visited_rooms, new_room);
		
		if (new_room.has_key) { 
			if (new_room.chest_obj != obj_key || !new_room.has_locked_chest || array_contains(unlocked_chests, new_room)) {
				collect_key();
			}
		}
		else if (new_room.stairs_spot_obj != obj_cross && new_room.stairs_spot_obj != obj_encased_heart) { array_push(keyless_visited_rooms, new_room); }
		
		if (new_room.has_locked_chest) { array_push(encountered_locks, [-1, new_room, walk_distance]); }
		
		// Update trip future
		for (var i = 0; i <= directions.stairs; i += 1;) {
			var dir = (start_dir + i) % 5;
			if (new_room.exits[dir] && new_room.adj_rooms[dir] != noone) {
				// If there is a next room in this direction
				var next_room = new_room.adj_rooms[dir], locked_exit_to_next_room = new_room.locked_exits[dir];
				if (locked_exit_to_next_room == noone || array_contains(unlocked_exits, locked_exit_to_next_room)) { visit_room(next_room); }
				else { array_push(encountered_locks, [get_opposite_dir(dir), locked_exit_to_next_room, walk_distance]); }
			}
		}
		
		return true;
	}
	
	function has_visited_all_rooms() {
		return (array_length(visited_rooms) == array_length(global.controller.game_rooms));
	}
	
	function duplicate_current_state(other_walker) {
		var new_walker = new MapWalker(other_walker.start_dir);
		
		with (new_walker) {
			// Trip History
			array_duplicate(visited_rooms, other_walker.visited_rooms);
			array_duplicate(keyless_visited_rooms, other_walker.keyless_visited_rooms);
			array_duplicate(encountered_locks, other_walker.encountered_locks);
			array_duplicate(unlocked_exits, other_walker.unlocked_exits);
			array_duplicate(unlocked_chests, other_walker.unlocked_chests);
	
			// Trip Present
			current_room = other_walker.current_room;
			keys_found = other_walker.keys_found;
			keys_remaining = other_walker.keys_remaining;
			has_found_special_key = other_walker.has_found_special_key;
			walk_distance = other_walker.walk_distance;
			min_key_distance = other_walker.min_key_distance;
		}
		
		return new_walker;
	}
	
	function walk_the_map(start_room) {
		// Set up initial state by visiting the given room.
		visit_room(start_room);
		
		if (has_visited_all_rooms()) {
			// Visited all rooms; successfully walked the map
			return true;
		}
		else if (keys_remaining == 0) {
			// Failed to visit all rooms; map is not possible
			return false;
		}
		else {
			// Decision point. Make a copy of this decision point to test each branch from
			var original_map_walker = new MapWalker(start_dir);
			original_map_walker.duplicate_current_state(self);
			
			// Test each decision branch possible at this point
			while (array_length(encountered_locks) > 0) {
				// Set state back to copy of decision point
				duplicate_current_state(original_map_walker);
				
				// Set up descision branch
				var next_encountered_lock = array_random_pop(encountered_locks);
				var dir = next_encountered_lock[0], next_room_to_enter = noone;
				var dist_at_lock = next_encountered_lock[2], dist_from_lock = 0;
				if (min_key_distance > dist_at_lock) { dist_from_lock = min_key_distance - dist_at_lock; }
				walk_distance = dist_at_lock + dist_from_lock*2;
				
				// Unlock a random exit to test that decision branch
				if (!has_found_special_key) { spend_key(); }
				if (dir < 0) { 
					// Unlock Chest
					next_room_to_enter = next_encountered_lock[1];
					if (next_room_to_enter.chest_obj == obj_key) { 
						collect_key();
						if (next_room_to_enter.has_special_item) { has_found_special_key = true; }
					}
					array_push(unlocked_chests, next_room_to_enter);
				}
				else {
					// Unlock Exit
					var next_encountered_exit = next_encountered_lock[1];
					next_room_to_enter = next_encountered_exit.get_room_in_direction(dir);
					array_push(unlocked_exits, next_encountered_exit);
				}
				
				// Walk this decision branch
				var successful_walk = walk_the_map(next_room_to_enter);
				
				if (!successful_walk) { 
					// One decision branch is impossible, so walking the map from this point failed.
					return false;
				}
			}
			
			// All decision branches were possible, so walking the map from this point succeeded.
			return true;
		}
	}
}

/// @function								attempt_to_walk_the_map();
function get_new_map_walk_attempt(dir) {
	var new_walker = new MapWalker(dir);
	new_walker.walk_the_map(global.controller.start_room)
	return new_walker;
}

/// @function								set_up_locks_and_keys();
function set_up_locks_and_keys() {
	var map_walker = get_new_map_walk_attempt(directions.up);
	//return map_walker
	while (!map_walker.has_visited_all_rooms()) {
		if (array_length(map_walker.keyless_visited_rooms) > 0) {
			var room_to_add_key_to = array_random_pop(map_walker.keyless_visited_rooms);
			with (room_to_add_key_to) { set_up_room_key(); }
			show_debug_message("NUMBER OF KEYS +1");
		}
	    else if (array_length(map_walker.encountered_locks) > 0) {
			var lock_to_unlock = array_random_pop(map_walker.encountered_locks);
			while (lock_to_unlock[0] < 0 && array_length(map_walker.encountered_locks) > 0) {
				lock_to_unlock = array_random_pop(map_walker.encountered_locks);
			}
			
			if (lock_to_unlock[0] >= 0) {
				lock_to_unlock[1].remove();
				show_debug_message("NUMBER OF LOCKS -1");
			}
			else {
				// Should never need to reach this clause
				return map_walker;
			}
		}
		else {
			// Should never need to reach this clause
			return map_walker;
		}
		
		map_walker = get_new_map_walk_attempt(directions.up);
	}
	
	return map_walker;
}
