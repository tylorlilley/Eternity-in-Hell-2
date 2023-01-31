// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.FARM_MODE) { sprite_prefetch(spr_player_farmer); }

// Initialize global values
random_set_seed(global.seed);
show_debug_message("SEED: "+string(random_get_seed()));
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

// Restart Room Spawning if room count is too high
var total_rooms = array_length(game_rooms);
if (total_rooms > MINIMUM_NUMBER_OF_ROOMS * 1.5) {
	show_debug_message("WARNING: too many rooms required.");
	reset_map_generation();
	exit;
}
else {

// Generate stairs Connections
var rooms_with_stairs_spot = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	if (game_rooms[i].exits[4]) { array_push(rooms_with_stairs_spot, game_rooms[i]); }
}
if (modulo(array_length(rooms_with_stairs_spot), 2) != 0) {
	var odd_room_out = array_random_pop(rooms_with_stairs_spot);
	odd_room_out.exits[4] = false;
	odd_room_out.stairs_spot_obj = -1;
	array_remove(rooms_with_stairs_spot, odd_room_out);
}
while (array_length(rooms_with_stairs_spot) > 0) {
	var first_room = array_random_pop(rooms_with_stairs_spot);
	var second_room = array_random_pop(rooms_with_stairs_spot);
	first_room.adj_rooms[4] = second_room;
	second_room.adj_rooms[4] = first_room;
}

// Lock Random Exits
locked_exits = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	for(var dir = 0; dir <= 3; dir+= 1;) {
	    if (game_rooms[i].exits[dir] && get_random_chance_out_of(LOCKED_DOOR_PROBABILITY)) { 
	        array_push(locked_exits, game_rooms[i].create_locked_exit(dir));
	    }
	}
}

// Begin Game in Random Room that has no stairs in it
var start_pos = irandom(total_rooms-1);
for (var i = 0; i < total_rooms; i++) {
	var current_pos = (i+start_pos) % total_rooms;

	current_room = game_rooms[current_pos];
	if (current_room.stairs_spot_obj == -1) { start_room = current_room; break; }
}
			
if (start_room == noone) {
	// Should never need to reach this clause
	show_debug_message("WARNING: random start room choice messed up.");
	reset_map_generation();
	exit;
}

if (start_room.has_collectables) {
	start_room.has_collectables = false;
	array_remove(rooms_with_collectables, array_get_index(rooms_with_collectables, start_room));
}
start_room.has_portcullis = false;
current_room.calculate_distance_to_current_room(0);

// Set up lists used to walk the map
var keyless_rooms = array_create(0), farthest_rooms = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	// Determine if room has a key or not
	if (!game_rooms[i].has_keys > 0 && game_rooms[i] != current_room) { array_push(keyless_rooms, game_rooms[i]); }
}

// Randomly spawn a minimum number of collectables rooms
while (array_length(rooms_with_collectables) < MINIMUM_COLLECTABLES_ROOMS) {
	var new_collectables_room = array_random_get(game_rooms);
	if (new_collectables_room == start_room) { continue; }
	
	if (!new_collectables_room.has_collectables) {
		new_collectables_room.has_collectables = true;
		array_push(rooms_with_collectables, new_collectables_room);
	}
}

// Walk the Map and tweak it until map is possible
keyless_rooms = set_up_locks_and_keys(keyless_rooms);

// Create heart in farthest room
for (var i = 0; i < total_rooms; i++) {
	if (game_rooms[i].exits[4] == false && game_rooms[i].stairs_spot_obj == -1) {
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

// Lock all exits to heart room
with array_random_pop(farthest_rooms) {
	if (!has_collectables) {
		has_collectables = true;
		array_push(other.rooms_with_collectables, self);
	}
	stairs_spot_obj = obj_encased_heart;
	for (var i = 0; i <= 3; i += 1;) {
		if (exits[i]) { create_locked_exit(i); }
	}
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);

// Set up locks and keys again to ensure the heart room is always accesable
keyless_rooms = set_up_locks_and_keys(keyless_rooms);

// Setup room references
create_room_lists();
time_provided = 0;

var item_spawned = false, rooms_with_lanterns = array_create(0), rooms_without_stairs_spot_obj = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	// Assign room reference from list
	var given_room = game_rooms[i];
	given_room.room_reference = given_room.get_room_from_room_lists();
   
	// Add room to approprite room lists
	with (given_room) {
		if (get_room_reference_object_count(obj_lantern) > 0) { array_push(rooms_with_lanterns, self); }
		if (stairs_spot_obj == -1) {  array_push(rooms_without_stairs_spot_obj, self); }
		else if (chest_obj == -1 && stairs_spot_obj == obj_chest) { item_spawned = true; }
	}
	
	// Add game time based on assigned room reference
	var room_difficulty = difficulty_for_room_reference(game_rooms[i].room_reference);
	var room_time_provided = TIME_PROVIDED_PER_ROOM;
	if (room_difficulty == difficulties.easy) { room_time_provided += TIME_PROVIDED_PER_EASY_ROOM; }
	if (room_difficulty == difficulties.hard) { room_time_provided += TIME_PROVIDED_PER_HARD_ROOM; }
	if (current_room.has_collectables) { room_time_provided += TIME_PROVIDED_PER_COLLECTABLE; }
	if (current_room.misleading_room) { room_time_provided += TIME_PROVIDED_PER_DEAD_END; }
	for (var j = 0; j < 4; j++) {
		if (current_room.locked_exits[j]) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
	}
	time_provided += room_time_provided;
}

// Ensure at least one lantern room exists
if (array_length(rooms_with_lanterns) == 0) {
	show_debug_message("WARNING: no lantern rooms generated.");
	reset_map_generation();
	exit;
}

// Ensure at least one item room exists
if (!item_spawned && array_length(rooms_without_stairs_spot_obj) == 0) {
	show_debug_message("WARNING: no item chest generated and no rooms where one can be generated.");
	reset_map_generation();
	exit;
}

// Pre-light some rooms
var lit_room_exists = false;
for (var i = 0; i < array_length(rooms_with_lanterns); i++) {
	var given_room = rooms_with_lanterns[i];
	given_room.lit = get_random_chance_out_of(PRE_LIT_PROBABILITY);
	if (given_room.lit) { lit_room_exists = true; }
}

// Ensure at least one room is pre-lit
if (!lit_room_exists) {
	var given_room = array_random_get(rooms_with_lanterns);
	given_room.lit = true;
}

// Ensure at least one room has item
if (!item_spawned) {
	var given_room = array_random_get(rooms_without_stairs_spot_obj);
	with given_room { set_up_room_chest(); }
}

// Spawn an item for each room that needs it
for (var i = 0; i < array_length(rooms_with_item); i++) {
	var spawned_item_obj = (i == 0) ? obj_map : get_random_item_obj(false, false);
	array_push(spawned_items, spawned_item_obj);
	show_debug_message("SPAWNED " + object_get_name(spawned_item_obj));
}

// Create player object and change room to current room's referenced room
time_remaining = time_provided;
current_room.stairs_spot_obj = obj_cross;
global.player = instance_create(8, 8, obj_player);
current_room.go_to_room();

/*
avg_exits = 0;
one_exits = 0;
two_exits_opp = 0;
two_exits_perp = 0;
three_exits = 0;
four_exits = 0;
for (var i = 0; i < total_rooms; i++) {
	var counted_exits = game_rooms[i].get_exits_count();
	avg_exits += counted_exits;
	if counted_exits == 1 one_exits += 1;
	if counted_exits == 3 three_exits += 1;
	if counted_exits == 4 four_exits += 1;
	if counted_exits == 2 {
		if game_rooms[i].exits[0] && game_rooms[i].exits[2] { two_exits_opp += 1; }
		else if game_rooms[i].exits[1] && game_rooms[i].exits[3] { two_exits_opp += 1; }
		else { two_exits_perp += 1; }
	}
}
avg_exits = avg_exits / total_rooms;
*/
}


