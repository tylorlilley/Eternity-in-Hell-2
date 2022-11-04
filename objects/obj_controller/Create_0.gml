global.zero_room = noone;

// Initialize global values
randomize()
//random_set_seed(1080708209);
clear_inputs_for_next_frame();
initialize_game_variables();

// Generate Initial Room with Four Exits
var uninitialized_rooms = array_create(0) // Used by functions called add_random_exit and initialized_room
current_room = new GameRoom(0,0);
current_room.exits = [true, true, true, true, false];
array_push(game_rooms, current_room);
with current_room { initialize_room(uninitialized_rooms); }

// Generate More Rooms until minimum number is met.
var target_number_of_rooms = MINIMUM_NUMBER_OF_ROOMS + irandom(ADDITIONAL_ROOMS);
while (array_length(game_rooms) < target_number_of_rooms) {
    var random_room = array_random_get(game_rooms);
    with random_room { add_random_exit(true, uninitialized_rooms); }
	//show_debug_message("Added room exit to game room " + string(random_room.id))
}

// Generate and initialize rooms until all rooms have been initialized
while (array_length(uninitialized_rooms) > 0) {
    var random_uninitialized_room = array_random_pop(uninitialized_rooms);
    with random_uninitialized_room { initialize_room(uninitialized_rooms); }
}

// Generate stairs Connections
var rooms_with_stairs_spot = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
    if (game_rooms[i].exits[4]) { array_push(rooms_with_stairs_spot, game_rooms[i]); }
}
if (array_length(rooms_with_stairs_spot) mod 2 != 0) {
    var odd_room_out = array_random_pop(rooms_with_stairs_spot);
    odd_room_out.exits[4] = false;
	odd_room_out.stairs_spot_obj = noone;
    array_remove(rooms_with_stairs_spot, odd_room_out);
}
while (array_length(rooms_with_stairs_spot) > 0) {
	var first_room = array_random_pop(rooms_with_stairs_spot);
    var second_room = array_random_pop(rooms_with_stairs_spot);
    first_room.adj_rooms[4] = second_room;
    second_room.adj_rooms[4] = first_room;
}

// Assign a room reference from possible rooms for each room
create_room_lists();
for (var i = 0; i < array_length(game_rooms); i++) {
   game_rooms[i].room_reference = game_rooms[i].get_room_from_room_lists();
   game_rooms[i].get_reachable_exits();
}

// Lock Random Exits
var locked_exits = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
    for(var dir = 0; dir <= 3; dir+= 1;) {
        if (game_rooms[i].exits[dir] && get_random_chance_out_of(LOCKED_DOOR_PROBABILITY)) { 
           array_push(locked_exits, game_rooms[i].create_locked_exit(dir));
        }
    }
}

// Begin Game in Random Room that has no stairs in it
var random_pos = irandom(array_length(game_rooms)-2);
for (var i = random_pos+1; i < array_length(game_rooms); i++) {
	if (i == array_length(game_rooms)) { i = 0; }
	if (i == random_pos) {
		// Should never need to reach this clause
		show_debug_message("WARNING: random start room choice messed up.");
		restart_game();
	}
	current_room = game_rooms[i];
	if (!current_room.stairs_spot_obj) { break; }
}
current_room.calculate_distance_to_current(0);
start_room = current_room;

// Set up lists used to walk the map
var keyless_rooms = array_create(0), farthest_rooms = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
	// Determine if room has a key or not
    if (!game_rooms[i].has_key && game_rooms[i] != current_room) { array_push(keyless_rooms, game_rooms[i]); }
}

// Randomly spawn a special item for each item type
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);
if (array_length(rooms_with_key) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with array_random_pop(rooms_with_key) { has_special_item = true; show_debug_message("RED KEY"); } }
if (array_length(rooms_with_torch) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with array_random_pop(rooms_with_torch) { has_special_item = true; show_debug_message("RED TORCH"); } }
if (array_length(rooms_with_sword) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with array_random_pop(rooms_with_sword) { has_special_item = true; show_debug_message("RED SWORD"); } }
if (array_length(rooms_with_rosary) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with array_random_pop(rooms_with_rosary) { has_special_item = true; show_debug_message("RED ROSARY"); } }
if (array_length(rooms_with_map) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with array_random_pop(rooms_with_map) { has_special_item = true; show_debug_message("RED MAP"); } }

// Walk the Map and tweak it until map is possible
//show_debug_message("NUMBER OF KEYS: "+string(array_length(game_rooms) - (array_length(keyless_rooms)+1)));
//show_debug_message("NUMBER LOCKED DOORS: "+string(array_length(locked_exits)));
var visited_all_rooms = is_current_map_possible();
while (!visited_all_rooms) {
	var number_of_keys = array_length(game_rooms) - (array_length(keyless_rooms)+1);
	var number_of_locked_exits = array_length(locked_exits);
	
    // Add an additional key somewhere
    if (array_length(keyless_rooms) > 0 && (array_length(locked_exits) == 0 || number_of_keys <= number_of_locked_exits*1.5)) {
        var room_to_add_key_to = array_random_pop(keyless_rooms);
		room_to_add_key_to.has_key = true;
		array_push(rooms_with_key, room_to_add_key_to);
		//show_debug_message("NUMBER OF KEYS +1");
    }
    // Remove one of the locked doors and reset all rooms to have no keys
    else if (array_length(locked_exits) > 0) {
        with array_random_pop(locked_exits) { remove(); }
		for (var i = 0; i < array_length(game_rooms); i++) {
		    if (game_rooms[i].has_key) { game_rooms[i].has_key = false; array_push(keyless_rooms, game_rooms[i]); }
		}
		rooms_with_key = array_create(0);
		//show_debug_message("KEYS RESET; NUMBER OF LOCKS -1");
    }
	// Should never need to reach this clause
	else {
		show_debug_message("WARNING: lock generation screwed up.");
		restart_game();
	}
	
	visited_all_rooms = is_current_map_possible();
}
//show_debug_message("WALK RESULTS: "+string(visited_all_rooms));
//show_debug_message("NUMBER OF KEYS: "+string(array_length(game_rooms) - (array_length(keyless_rooms)+1)));
//show_debug_message("NUMBER LOCKED DOORS: "+string(array_length(locked_exits)));

// Create heart in farthest room
for (var i = 0; i < array_length(game_rooms); i++) {
	if (!game_rooms[i].exits[4] && !game_rooms[i].stairs_spot_obj) {
		if (array_length(farthest_rooms) == 0) { array_push(farthest_rooms, game_rooms[i]); }
		else {
			var distance = array_get(farthest_rooms, 0).distance_from_start_room;
			if (game_rooms[i].distance_from_start_room == distance) {
				array_push(farthest_rooms, game_rooms[i]);
			}
			else if (game_rooms[i].distance_from_start_room > distance){
				farthest_rooms = array_create(0);
				array_push(farthest_rooms, game_rooms[i]);
			}
		}
	}
}
with array_random_pop(farthest_rooms) {
	stairs_spot_obj = obj_encased_heart;
	for (var i = 0; i <= 3; i += 1;) {
		if (exits[i]) { create_locked_exit(i); }
	}
}

// Set up point and time related variables
time_provided = (array_length(game_rooms) * TIME_PROVIDED_PER_ROOM) + (array_length(locked_exits) * TIME_PROVIEDED_PER_LOCK);
time_remaining = time_provided;

// Create player object and change room to current room's referenced room
current_room.stairs_spot_obj = obj_cross;
global.player = instance_create_depth(0, 0, -10, obj_player);
current_room.go_to_room();
show_debug_message("SEED: "+string(random_get_seed()));

avg_exits = 0;
one_exits = 0;
two_exits = 0;
three_exits = 0;
four_exits = 0;
for (var i = 0; i < array_length(game_rooms); i++) {
	var counted_exits = game_rooms[i].count_exits();
	avg_exits += counted_exits;
	if counted_exits == 1 one_exits += 1;
	if counted_exits == 2 two_exits += 1;
	if counted_exits == 3 three_exits += 1;
	if counted_exits == 4 four_exits += 1;
}
avg_exits = avg_exits / array_length(game_rooms);

