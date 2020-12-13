/// @function								initialize(list_of_rooms);
/// @param	{index}	list_of_rooms			The list of available rooms
function initialize_room(list_of_rooms) {
	// Randomly decide if room will have collectables, stairs, or keys
	if (irandom(100) < global.controller.HAS_KEY_PROBABILITY) { has_key = true; }
	if (irandom(100) < global.controller.HAS_STAIRS_PROBABILITY) { exits[4] = true; }
	if (irandom(100) < global.controller.HAS_COLLECTABLE_PROBABILITY) { 
	    has_collectables = true; 
	    global.controller.rooms_with_collectables += 1; 
	}

	// Randomly determine the number of exits this room should have based on probability weighting
	var target_number_of_exits = 0;
	var rand = irandom(100)-instance_number(obj_room); // subtract number of rooms in order to drive generation toward an end eventually
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
	
/// @fucntion								get_adjacent_room(dir);
/// @param		{direction}	dir				The direction from this room to the adjacent room to get
function get_adjacent_room(dir) {
	var x_pos = 0;
	var y_pos = 0;

	switch (dir)
	{
	    case 0: { y_pos = -16; break; }
	    case 1: { x_pos = 16; break; }
	    case 2: { y_pos = 16; break; }
	    case 3: { x_pos = -16; break; }
	}

	return instance_position(x+x_pos, y+y_pos, obj_room);
}

/// @function								create_adjoining_room(dir, list_of_rooms);
///	@param		{direction}	dir				The direction from this room in which to create the adjoining room
/// @param		{index}		list_of_rooms	The list of all created rooms
function create_adjoining_room(dir, list_of_rooms) {
	var x_offset = 0
	var y_offset = 0;

	switch(dir)
	{
	    case 0: { y_offset = -16; break; }
	    case 1: { x_offset = 16; break; }
	    case 2: { y_offset = 16; break; }
	    case 3: { x_offset = -16; break; }
	}

	var new_room = instance_create_depth(x+x_offset, y+y_offset, 0, obj_room);
	link_adjoining_room(new_room, dir);
	ds_list_add(list_of_rooms, new_room);
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


/// @function								create_locked_exit(dir);
/// @param		{direction}		dir			The directional exit of the room to create a locked exit in.
function create_locked_exit(dir) {
	var new_locked_exit = instance_create_depth(0,0,0,obj_exit); 
	
	new_locked_exit.room_1 = id;
	new_locked_exit.room_1_dir = dir;
	new_locked_exit.room_2 = adj_rooms[dir];
	new_locked_exit.room_2_dir = opposite_dir(dir);
	new_locked_exit.room_1.locked_exits[new_locked_exit.room_1_dir] = new_locked_exit;
	new_locked_exit.room_2.locked_exits[new_locked_exit.room_2_dir] = new_locked_exit;
	
	return new_locked_exit;
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
	if (global.controller.TEST_MODE || visited) {
	    // Draw Room, fading it based on its distance to the current room. Make it blink if it is the current room
	    var room_image_alpha = 1-(distance_to_current_room/global.controller.MAX_MAP_DRAW_DISTANCE);
	    if (global.controller.current_room.id == id && global.controller.number_of_frames_since_game_began mod 12 == 0) { room_image_alpha /= 2; }
		room_color = lit ? c_red : c_white
		draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.875, 0.875, 0, room_color, room_image_alpha);

	    // Draw Room's Exits
	    for (var i = 0; i < 4; i++) {
	        // Change the color of just the locked exits if the game is in test mode
	        if (global.controller.TEST_MODE && locked_exits[i]) { draw_set_color(c_red); }
	        else { draw_set_color(global.controller.bg_color); }
        
	        var x_offset = 0;
	        var y_offset = 0;
	        var x_size = 0.25;
	        var y_size = 0.25;
        
	        if (i == 0) { y_offset = -8; y_size += 0.125; } 
	        if (i == 1) { x_offset = 8; x_size += 0.125; } 
	        if (i == 2) { y_offset = 8; y_size += 0.125; } 
	        if (i == 3) { x_offset = -8; x_size += 0.125; } 

	        if exits[i] draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, draw_get_color(), 1);
	    }
	    // Draw Room's Stairs
	    draw_set_color(global.controller.bg_color);
	    if exits[4] draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.125, 0.125, 0, draw_get_color(), 1);
	    // Draw Room's Keys if game is in test mode
	    if (global.controller.TEST_MODE && has_key) { draw_set_color(c_red); draw_sprite_ext(spr_box, 0, x_pos-4, y_pos-4, 0.125, 0.125, 0, draw_get_color(), 1); }
    
	    // Draw distance information if testing
	    if (global.controller.TEST_MODE) {
	        draw_set_color(c_lime);
	        draw_set_halign(fa_center);
	        draw_set_valign(fa_middle);
	        if (distance_to_current_room < 9999) { draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_current_room))); }
	    }
	}

	// Mark the room as having been drawn, then draw each of its applicable neighbors
	drawn = true;
	if (distance_to_current_room < global.controller.MAX_MAP_DRAW_DISTANCE || game_has_been_lost() || game_has_been_won()) {
	  if (adj_rooms[0] && !adj_rooms[0].drawn && y_pos-16 >= 0) with adj_rooms[0] { draw_room(x_pos, y_pos-16); }
	  if (adj_rooms[1] && !adj_rooms[1].drawn && x_pos+16 <= room_width) with adj_rooms[1] { draw_room(x_pos+16, y_pos); }
	  if (adj_rooms[2] && !adj_rooms[2].drawn && y_pos+16 <= room_height) with adj_rooms[2] { draw_room(x_pos, y_pos+16); }
	  if (adj_rooms[3] && !adj_rooms[3].drawn && x_pos-16 >= 0) with adj_rooms[3] { draw_room(x_pos-16, y_pos); }
	}
}




