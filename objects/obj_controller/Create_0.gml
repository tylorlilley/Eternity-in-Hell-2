// Initialize global values
// global.seed = 24034153
random_set_seed(global.seed);
show_debug_message("SEED: "+string(random_get_seed()));
clear_inputs_for_next_frame();
initialize_game_variables();
//global.TEST_MODE = true;

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
}
else {

// Generate stairs Connections
var rooms_with_stairs_spot = array_create(0);
for (var i = 0; i < total_rooms; i++) {
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
	if (current_room.stairs_spot_obj == noone) { start_room = current_room; break; }
}
			
if (start_room == noone) {
	// Should never need to reach this clause
	show_debug_message("WARNING: random start room choice messed up.");
	reset_map_generation();
}

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
	new_collectables_room.has_collectables = true;
	array_push(rooms_with_collectables, new_collectables_room);
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);

// Walk the Map and tweak it until map is possible
keyless_rooms = set_up_locks_and_keys(keyless_rooms);

// Create heart in farthest room
for (var i = 0; i < total_rooms; i++) {
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
keyless_rooms = set_up_locks_and_keys(keyless_rooms);

// Set up point and time related variables and room references
create_room_lists();
time_provided = 0;
for (var i = 0; i < total_rooms; i++) {
	var given_room = game_rooms[i];
	
	// Assign room reference from list
   given_room.room_reference = given_room.get_room_from_room_lists();
   
   // Update room based on assigned room reference
   with (given_room) {
	   if (get_room_reference_object_count(obj_lantern) == 0) { lit = false; }
	   if (global.TEST_MODE) {
		   if (get_room_reference_object_count(obj_collectable_spot) < 2) { show_debug_message("WARNING: not enough collectable spots in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_stairs_spot) != 1) { show_debug_message("WARNING: not exactly one stairs spot in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_collectable) > 0) { show_debug_message("WARNING: obj_collectable in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_block) > 0) { show_debug_message("WARNING: obj_block in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_stairs) > 0) { show_debug_message("WARNING: obj_stairs in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_hole) > 0) { show_debug_message("WARNING: obj_hole in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_cross) > 0) { show_debug_message("WARNING: obj_cross in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_encased_heart) > 0) { show_debug_message("WARNING: obj_encased_heart in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_echo) > 0) { show_debug_message("WARNING: obj_echo in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_chest) > 0) { show_debug_message("WARNING: obj_echo in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_fireball) > 0) { show_debug_message("WARNING: obj_echo in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_phantom) > 0) { show_debug_message("WARNING: obj_phantom in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_nose) > 0) { show_debug_message("WARNING: obj_nose in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_hands) > 0) { show_debug_message("WARNING: obj_hands in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_title) > 0) { show_debug_message("WARNING: obj_echo in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_sound_manager) > 0) { show_debug_message("WARNING: obj_sound_manager in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_controller) > 0) { show_debug_message("WARNING: obj_controller in room "+room_get_name(room_reference)); } 
		   if (get_room_reference_object_count(obj_player) > 0) { show_debug_message("WARNING: obj_player in room "+room_get_name(room_reference)); }
	   }
   }
   
   
   // Add game time based on assigned room reference
   var room_difficulty = get_room_difficulty(game_rooms[i].room_reference);
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
time_remaining = time_provided;

// Create player object and change room to current room's referenced room
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

