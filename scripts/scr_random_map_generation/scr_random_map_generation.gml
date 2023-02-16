function MapWalker(dir) constructor {
	// Trip History
	visited_rooms = array_create(0);
	keyless_visited_rooms = array_create(0);
	remaining_locks = array_create(0);
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
		
		if (new_room.has_locked_chest) { array_push(remaining_locks, [-1, new_room, walk_distance]); }
		
		// Update trip future
		for (var i = 0; i <= directions.stairs; i += 1;) {
			var dir = (start_dir + i) % 5;
			if (new_room.has_exit_in_dir[dir] && new_room.adj_rooms[dir] != noone) {
				// If there is a next room in this direction
				var next_room = new_room.adj_rooms[dir], exit_to_next_room = new_room.exits[dir];
				if (exit_to_next_room == noone || !exit_to_next_room.locked || array_contains(unlocked_exits, exit_to_next_room)) { visit_room(next_room); }
				else { array_push(remaining_locks, [get_opposite_dir(dir), exit_to_next_room, walk_distance]); }
			}
		}
		
		return true;
	}
	
	function has_visited_all_rooms() {
		return (array_length(visited_rooms) == array_length(global.controller.game_rooms));
	}
	
	function duplicate_state_from(other_walker) {
		// Reset arrays
        visited_rooms = array_create(0);
        keyless_visited_rooms = array_create(0);
        remaining_locks = array_create(0);
        unlocked_exits = array_create(0);
        unlocked_chests = array_create(0);
        
        // Copy trip history
        array_duplicate(visited_rooms, other_walker.visited_rooms);
        array_duplicate(keyless_visited_rooms, other_walker.keyless_visited_rooms);
        array_duplicate(remaining_locks, other_walker.remaining_locks);
        array_duplicate(unlocked_exits, other_walker.unlocked_exits);
        array_duplicate(unlocked_chests, other_walker.unlocked_chests);
    
        // Copy trip Present
        current_room = other_walker.current_room;
        keys_found = other_walker.keys_found;
        keys_remaining = other_walker.keys_remaining;
        has_found_special_key = other_walker.has_found_special_key;
        walk_distance = other_walker.walk_distance;
        min_key_distance = other_walker.min_key_distance;
        start_dir = other_walker.start_dir
	}
	
	function unlock_lock(lock_to_unlock) {
		var dir = lock_to_unlock[0], room_with_lock = noone;
		var dist_at_lock = lock_to_unlock[2], dist_from_lock = 0;
				
		if (min_key_distance > dist_at_lock) { dist_from_lock = min_key_distance - dist_at_lock; }
		walk_distance = dist_at_lock + dist_from_lock*2;

		// Unlock the encountered lock to test that decision branch
		if (!has_found_special_key) { spend_key(); }
		if (dir < 0) {
			// Unlock Chest
			room_with_lock = lock_to_unlock[1];
			if (room_with_lock.chest_obj == obj_key) {
				collect_key();
				if (room_with_lock.has_special_item) { has_found_special_key = true; }
			}
			array_push(unlocked_chests, room_with_lock);
		}
		else {
			// Unlock Exit
			var next_encountered_exit = lock_to_unlock[1];
			room_with_lock = next_encountered_exit.get_room_in_direction(dir);
			array_push(unlocked_exits, next_encountered_exit);
		}
		
		return room_with_lock;
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
		else if (array_length(remaining_locks) == 1) {
			var only_lock = array_pop(remaining_locks);
			var room_with_lock = unlock_lock(only_lock)
			return visit_room(room_with_lock);
		}
		else {
			// Decision point. Make a copy of this decision point to test each branch from
			var original_map_walker = new MapWalker(start_dir), original_remaining_locks = array_create(0);
			array_duplicate(original_remaining_locks, remaining_locks);
			original_map_walker.duplicate_state_from(self);

			// Test each decision branch possible at this point
			for (var i = 0; i < array_length(original_remaining_locks); i++) {
				// Set state back to copy of decision point
				duplicate_state_from(original_map_walker);

				// Set up descision branch
				var next_encountered_lock = original_remaining_locks[i];
				array_remove(remaining_locks, next_encountered_lock);
				var room_with_lock = unlock_lock(next_encountered_lock);

				// Walk this decision branch
				var successful_walk = walk_the_map(room_with_lock);

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
		// Determine the number of keys needed to reach each new room encountered behind locks
		var minimum_new_keys_needed = 0, keys_added = 0, new_reachable_rooms = array_create(0), max_possible_new_keys = array_length(map_walker.keyless_visited_rooms);
		for (var i = 0; i < array_length(map_walker.remaining_locks); i++;) {
			var next_lock = map_walker.remaining_locks[i];
			if (next_lock[0] != -1) {
				// lock is not a chest
				var locked_room = next_lock[1];
				array_push(new_reachable_rooms, locked_room);
			}
		}
		new_reachable_rooms = array_unique(new_reachable_rooms);
		minimum_new_keys_needed = array_length(new_reachable_rooms);
		var total_locks_encountered = array_length(map_walker.remaining_locks) + map_walker.keys_found, new_total_keys = map_walker.keys_found + minimum_new_keys_needed
		
		// If we can spawn enough keys for the minimum needed, do so and try again
		if (minimum_new_keys_needed <= max_possible_new_keys && (new_total_keys <= 1.5 * (total_locks_encountered) || array_length(map_walker.remaining_locks) == 0)) {
			while (keys_added < minimum_new_keys_needed) {
				keys_added++;
				var room_to_add_key_to = array_random_pop(map_walker.keyless_visited_rooms);
				with (room_to_add_key_to) { set_up_room_key(); }
			}
			show_debug_message("NUMBER OF KEYS +" + string(keys_added));
		}
		// Otherwise, remove one of the encountered locks and try again
	    else if (array_length(map_walker.remaining_locks) > 0) {
			// Determine which lock to unlock
			var lock_to_unlock = array_random_pop(map_walker.remaining_locks);
			while (lock_to_unlock[0] < 0 && array_length(map_walker.remaining_locks) > 0) {
				// Skip this lock if it is a locked chest
				lock_to_unlock = array_random_pop(map_walker.remaining_locks);
			}
			
			if (lock_to_unlock[0] >= 0) {
				// Remove exit lock and reset all non-special keys
				lock_to_unlock[1].remove();
				for (var i = 0; i < array_length(game_rooms); i++) {
					var next_room = game_rooms[i];
					if (!next_room.has_special_item || next_room.chest_obj != obj_key) { next_room.remove_room_key(); }
				}
				show_debug_message("NUMBER OF LOCKS -1");
			}
			else {
				// This should never happen if every room has a stairs spot
				show_debug_message("WARNING: no room to spawn keys and only locked chests to remove");
				return map_walker;
			}
		}
		else {
			// This should never happen if every room has a stairs spot
			show_debug_message("WARNING: no room to spawn keys and no locked exits to remove");
			return map_walker;
		}
		
		map_walker = get_new_map_walk_attempt(directions.up);
	}
	
	return map_walker;
}
