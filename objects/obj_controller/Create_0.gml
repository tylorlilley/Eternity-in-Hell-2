// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.is_farm_mode) { sprite_prefetch(spr_player_farmer); }

// Initialize global values
random_set_seed(global.seed);
show_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();

// Generate Initial Room with Four Exits
var uninitialized_rooms = array_create(0) // Used by functions called add_random_exit and initialized_room
current_room = new GameRoom(0,0);
current_room.has_exit_in_dir = [true, true, true, true, false];
array_push(game_rooms, current_room);
with current_room { initialize_room(uninitialized_rooms); }

// Generate More Rooms until minimum number is met.
var target_number_of_rooms = MINIMUM_NUMBER_OF_ROOMS;
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
if (total_rooms > MAXIMUM_NUMBER_OF_ROOMS) {
	show_debug_message("WARNING: too many rooms required.");
	reset_map_generation();
	exit;
}
else {

// Remove a stairs room if there are too many
if (modulo((array_length(rooms_with_stairs_and_exits) + array_length(rooms_with_only_stairs)), 2) != 0) {
	var odd_room_out = array_random_pop(rooms_with_stairs_and_exits);
	odd_room_out.remove_room_stairs();
}
// Connect rooms with only stairs exits together
while (array_length(rooms_with_only_stairs) > 0) {
	var room_without_exits = array_random_pop(rooms_with_only_stairs);
	var room_with_exits = array_random_pop(rooms_with_stairs_and_exits);
	if (room_with_exits == noone) {
		// Should never need to reach this clause
		show_debug_message("WARNING: not enough rooms with stairs AND exits generated.");
		reset_map_generation();
		exit;
	}
	else {
		room_without_exits.adj_rooms[directions.stairs] = room_with_exits;
		room_with_exits.adj_rooms[directions.stairs] = room_without_exits;
	}
}
// Connect remaining stairs rooms together
while (array_length(rooms_with_stairs_and_exits) > 0) {
	var first_room = array_random_pop(rooms_with_stairs_and_exits);
	var second_room = array_random_pop(rooms_with_stairs_and_exits);
	first_room.adj_rooms[directions.stairs] = second_room;
	second_room.adj_rooms[directions.stairs] = first_room;
}

// Lock Random Exits
locked_exits = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	for(var dir = directions.up; dir < directions.stairs; dir++;) {
	    if (game_rooms[i].has_exit_in_dir[dir] && get_random_chance_out_of(LOCKED_DOOR_PROBABILITY)) { 
	        array_push(locked_exits, game_rooms[i].create_locked_exit(dir));
	    }
	}
}

// Choose a start room to begin the game in
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

// Set up the start room
with (start_room) {
	has_portcullis = false;
	stairs_spot_obj = obj_cross;
	if (has_key) { remove_room_key(); }
	if (has_collectables) {
		has_collectables = false;
		array_remove(other.rooms_with_collectables, self);
	}
}

// Walk the map to initialize keys and map distances
var map_walker = set_up_locks_and_keys()
if (!map_walker.has_visited_all_rooms()) {
	// Should never need to reach this clause
	show_debug_message("WARNING: key generation screwed up.");
	reset_map_generation();
	exit;
}

// Determine the farthest rooms
for (var dir = 0; dir <= directions.stairs; dir++) { get_new_map_walk_attempt(dir); }

// Create a heart room
var farthest_rooms = array_create(0);
for (var i = 0; i < total_rooms; i++) {
	if (game_rooms[i].has_exit_in_dir[directions.stairs] == false && (!game_rooms[i].has_special_item || !game_rooms[i].chest_obj == obj_key)) {
		// Room is eligibile to host the heart
		if (array_length(farthest_rooms) == 0) { array_push(farthest_rooms, game_rooms[i]); }
		else {
			var distance = array_get(farthest_rooms, 0).distance_to_start_room;
			if (game_rooms[i].distance_to_start_room > distance) { farthest_rooms = array_create(0); }
			if (game_rooms[i].distance_to_start_room >= distance) { array_push(farthest_rooms, game_rooms[i]); }
		}
	}
}
heart_room = array_random_pop(farthest_rooms);

// Set up the heart room
with (heart_room) {
	remove_room_chest();
	has_portcullis = false;
	stairs_spot_obj = obj_encased_heart;
	if (has_key) { remove_room_key(); }
	if (!has_collectables) {
		has_collectables = true;
		array_push(other.rooms_with_collectables, self);
	}
	for (var dir = directions.up; dir < directions.stairs; dir += 1;) {
		if (has_exit_in_dir[dir]) { create_locked_exit(dir); }
	}
}

// Randomly spawn a minimum number of collectables rooms
while (array_length(rooms_with_collectables) < MINIMUM_COLLECTABLES_ROOMS) {
	var new_collectables_room = array_random_get(game_rooms);
	if (new_collectables_room == start_room || new_collectables_room == heart_room) { continue; }
	
	if (!new_collectables_room.has_collectables) {
		new_collectables_room.has_collectables = true;
		array_push(rooms_with_collectables, new_collectables_room);
	}
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);

// Spawn more keys to handle new locks
var map_walker = set_up_locks_and_keys()
if (!map_walker.has_visited_all_rooms()) {
	// Should never need to reach this clause
	show_debug_message("WARNING: second key generation screwed up.");
	reset_map_generation();
	exit;
}

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
	for (var dir = directions.up; dir < directions.stairs; dir++) {
		if (current_room.exits[dir] != noone) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
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

// Ensure at least one room has regular item
if (!item_spawned) {
	var given_room = array_random_get(rooms_without_stairs_spot_obj);
	array_push(rooms_with_item, given_room);
}

// Spawn an item for each room that needs it
for (var i = 0; i < array_length(rooms_with_item); i++) {
	var spawned_item_obj = (i == 0) ? obj_map : get_random_item_obj(false, false);
	array_push(spawned_items, spawned_item_obj);
	show_debug_message("SPAWNED " + object_get_name(spawned_item_obj) + " " + string(spawned_item_obj));
}
total_items = array_length(spawned_items) + array_length(spawned_special_items);

// Create player object and change room to current room's referenced room
time_remaining = time_provided;
global.player = instance_create(-16, -16, obj_player);
for (var i = 0; i < array_length(game_rooms); i++) {
	var next_room = game_rooms[i];
	next_room.go_to_room(false);
	initialize_room_transition_values();
}

with (global.game_manager) { sounds_to_play = array_create(0); }
play_sound(snd_torchlight, false);
start_room.go_to_room(true);
}


