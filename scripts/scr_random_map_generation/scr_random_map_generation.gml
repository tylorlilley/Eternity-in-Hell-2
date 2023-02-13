function MapWalker(dir) constructor {
	// Trip History
	visited_rooms = array_create(0);
	possible_new_key_rooms = array_create(0);
	unlocked_exits = array_create(0);
	unlocked_chests = array_create(0);
	has_found_special_key = false;
	keys_found = 0;
	
	// Trip Present
	keys_remaining = 0;
	walk_distance = 0;
	min_key_distance = 9999;
	start_dir = dir;
	
	// Trip Future
	reachable_rooms = array_create(0);
	reachable_locks = array_create(0);
	
	function duplicate_state_from(other_walker) {
        // Copy trip history
        array_duplicate(visited_rooms, other_walker.visited_rooms);
        array_duplicate(possible_new_key_rooms, other_walker.possible_new_key_rooms);
        array_duplicate(unlocked_exits, other_walker.unlocked_exits);
        array_duplicate(unlocked_chests, other_walker.unlocked_chests);
        keys_found = other_walker.keys_found;
        has_found_special_key = other_walker.has_found_special_key;
    
        // Copy trip Present
        keys_remaining = other_walker.keys_remaining;
        walk_distance = other_walker.walk_distance;
        min_key_distance = other_walker.min_key_distance;
        start_dir = other_walker.start_dir
		
		// Copy Trip Future
        array_duplicate(reachable_rooms, other_walker.reachable_rooms);
        array_duplicate(reachable_locks, other_walker.reachable_locks);
	}
	
	function has_visited_all_rooms() {
		return (array_length(visited_rooms) == array_length(global.controller.game_rooms));
	}
	
	function visit_all_reachable_rooms(start_room) {
		// Set up initial room to check
		array_push(reachable_rooms, start_room);
		
		// Visit each reachable room until no rooms are left to visit
		do {
			var next_room = array_pop(reachable_rooms);
			visit_room(next_room);
		}
		until (array_length(reachable_rooms) == 0);
	}
	
	
	function visit_room(new_room) {
		// Update distance to reach this room
		/*
		if (walk_distance < new_room.distance_to_start_room) { new_room.distance_to_start_room = walk_distance; }
		if (array_contains(visited_rooms, new_room)) { return false; }
		*/
		
		// Visit this unvisited room
		walk_distance += 1;
		array_push(visited_rooms, new_room);
		
		// Collect room's key
		if (new_room.has_key) { collect_key(); }
		else if (new_room.stairs_spot_obj != obj_cross && new_room.stairs_spot_obj != obj_encased_heart) { array_push(possible_new_key_rooms, new_room); }
		
		// Add room's exits to reachable rooms or encountered locks
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			var next_dir = (start_dir + dir) % 5, next_room = new_room.adj_rooms[next_dir], next_exit = new_room.exits[next_dir]
			// If there is an exit in this direction
			if (new_room.has_exit_in_dir[next_dir]) {
				if (next_exit == noone || !next_exit.locked || array_contains(unlocked_exits, next_exit)) {
					if (!array_contains(visited_rooms, next_room) && !array_contains(reachable_rooms, next_room)) {
						array_push(reachable_rooms, next_room);
					}
				}
				else { array_push(reachable_locks, [get_opposite_dir(next_dir), next_exit, walk_distance]); }
			}
		}
		
		return true;
	}
	
	function unlock_lock(lock_to_unlock) {
		// Spend key and remove reachable lock
		if (!has_found_special_key) { spend_key(); }
		array_remove(reachable_locks, lock_to_unlock);
		// Walk back to exit and unlock it
		var dir = lock_to_unlock[0], exit_to_unlock = lock_to_unlock[1], dist_at_lock = lock_to_unlock[2];
		walk_back_to_lock(dist_at_lock);
		return unlock_exit(exit_to_unlock, dir);
	}
	
	function walk_back_to_lock(dist_at_lock) {
		var dist_from_lock = 0;
		if (min_key_distance > dist_at_lock) { dist_from_lock = min_key_distance - dist_at_lock; }
		walk_distance = dist_at_lock + dist_from_lock*2;
	}
	
	function unlock_exit(exit_to_unlock, dir) {
		array_push(unlocked_exits, exit_to_unlock);
		return exit_to_unlock.get_room_in_direction(dir);
	}
	
	function collect_key() {
		if (walk_distance < min_key_distance) { min_key_distance = walk_distance; }
		keys_remaining += 1; 
		keys_found += 1;
	}
	
	function spend_key() {
		keys_remaining -= 1;
		if (keys_remaining == 0) { min_key_distance = 9999; }
	}
}

function get_failing_map_walker(start_dir, start_room) {
	// Set up initial branch to check
	var branches_to_check = array_create(0), failing_walker = noone;
	array_push(branches_to_check, [new MapWalker(start_dir), start_room]);
	
	// Check all branches
	while (array_length(branches_to_check) > 0) {
		var next_branch = array_pop(branches_to_check), next_walker = next_branch[0], next_room = next_branch[1];
		
		/// Visit all rooms that can be reached
		next_walker.visit_all_reachable_rooms(next_room);

		if (next_walker.has_visited_all_rooms()) {
			/// Visited all rooms; branch is possible
			continue;
		}
		else if (next_walker.keys_remaining == 0) {
			/// Failed to visit all rooms; branch is not possible
			failing_walker = next_walker;
			break;
		}
		else {
			/// Decision Point reached; add each branch to list to check
			for (var i = 0; i < array_length(next_walker.reachable_locks); i++) {
				var next_lock = next_walker.reachable_locks[i], new_walker = new MapWalker(start_dir);
				new_walker.duplicate_state_from(next_walker);
				var room_with_lock = new_walker.unlock_lock(next_lock);
				array_push(branches_to_check, [new_walker, room_with_lock]);
			}
		}
	}
	
	// Return any encountered failing walkers
	return failing_walker;
}

/// @function								set_up_locks_and_keys();
function set_up_locks_and_keys() {
	var map_walker = get_failing_map_walker(directions.up, start_room);
	//return map_walker
	while (map_walker != noone) {
		if (array_length(map_walker.possible_new_key_rooms) > 0) {
			// Add a new key to a visited keyless room
			show_debug_message("NUMBER OF KEYS +1");
			var room_to_add_key_to = array_random_pop(map_walker.possible_new_key_rooms);
			with (room_to_add_key_to) { set_up_room_key(); }
		}
	    else if (array_length(map_walker.reachable_locks) > 0) {
			// Otherwise, remove one of the encountered locks and remove all keys and try again
			show_debug_message("NUMBER OF LOCKS -1");
			var lock_to_unlock = array_random_pop(map_walker.reachable_locks);
			lock_to_unlock[1].remove();
			// Remove all keys
			for (var i = 0; i < array_length(game_rooms); i++) {
				var next_room = game_rooms[i];
				next_room.remove_room_key();
				//if (!next_room.has_special_item || next_room.chest_obj != obj_key) { next_room.remove_room_key(); }
			}
		}
		else {
			// This should never happen
			show_debug_message("WARNING: no room to spawn keys and no locked exits to remove");
			return map_walker;
		}
		
		map_walker = get_failing_map_walker(directions.up, start_room);
	}
}
		// Determine the number of keys needed to reach each new room encountered behind locks
		/*
		var minimum_new_keys_needed = 0, keys_added = 0, new_reachable_rooms = array_create(0), max_possible_new_keys = array_length(map_walker.possible_new_key_rooms);
		for (var i = 0; i < array_length(map_walker.reachable_locks); i++;) {
			var next_lock = map_walker.reachable_locks[i];
			if (next_lock[0] != -1) {
				// lock is not a chest
				var locked_room = next_lock[1];
				array_push(new_reachable_rooms, locked_room);
			}
		}
		new_reachable_rooms = array_unique(new_reachable_rooms);
		minimum_new_keys_needed = array_length(new_reachable_rooms);
		var total_locks_encountered = array_length(map_walker.reachable_rooms) + map_walker.keys_found, new_total_keys = map_walker.keys_found + minimum_new_keys_needed
		
		// If we can spawn enough keys for the minimum needed, do so and try again
		if (minimum_new_keys_needed <= max_possible_new_keys && (new_total_keys <= 1.5 * (total_locks_encountered) || array_length(map_walker.reachable_rooms) == 0)) {
			while (keys_added < minimum_new_keys_needed) {
				keys_added++;
				var room_to_add_key_to = array_random_pop(map_walker.possible_new_key_rooms);
				with (room_to_add_key_to) { set_up_room_key(); }
			}
			show_debug_message("NUMBER OF KEYS +" + string(keys_added));
		}
		*/
		
			
		/*
		// Determine which lock to unlock
		var lock_to_unlock = array_random_pop(map_walker.reachable_rooms);
		while (lock_to_unlock[0] < 0 && array_length(map_walker.reachable_rooms) > 0) {
			// Skip this lock if it is a locked chest
			lock_to_unlock = array_random_pop(map_walker.reachable_rooms);
		}
			
		if (lock_to_unlock[0] >= 0) {
			// Remove exit lock and reset all non-special keys
			show_debug_message("NUMBER OF LOCKS -1");
			lock_to_unlock[1].remove();
			for (var i = 0; i < array_length(game_rooms); i++) {
				var next_room = game_rooms[i];
				if (!next_room.has_special_item || next_room.chest_obj != obj_key) { next_room.remove_room_key(); }
			}
		}
		else {
			// This should never happen
			show_debug_message("WARNING: no room to spawn keys and only locked chests to remove");
			return map_walker;
		}
		*/
