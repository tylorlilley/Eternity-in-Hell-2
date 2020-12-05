/// @description  obj_room_add_random_exit(must_create_new, list_of_rooms)
function obj_room_add_random_exit(argument0, argument1) {
	var must_create_new = argument0, list_of_rooms = argument1;

	if (obj_room_count_exits() > 3 || (must_create_new && obj_room_count_adjacent_rooms() > 3)) { 
	    return false; 
	    // Impossible to create a new exit in this case. This method should not be called under
	    // These circumstances anyway, but this guard clause is here for protection.
	}

	// Randomly determine where the next exit position will be
	var next_exit_pos = irandom(3);
	do { next_exit_pos = (next_exit_pos+1) mod 4; }
	until (must_create_new && !obj_room_get_adjacent(next_exit_pos) ||
	       !must_create_new && !exits[next_exit_pos])

	// Create an exit at this position, then either link to the adjacent room that is in
	// that direction or create a new room in that direction
	exits[next_exit_pos] = true;
	var existing_room = obj_room_get_adjacent(next_exit_pos);
	if (existing_room) { obj_room_link_adjoining_room(existing_room, next_exit_pos); }
	else { obj_room_create_adjoining_room(next_exit_pos, list_of_rooms); }



}
