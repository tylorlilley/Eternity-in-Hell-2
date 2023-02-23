// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.is_farm_mode) { sprite_prefetch(spr_player_farmer); }
grid_update_timer = 0;

// Initialize global values
random_set_seed(global.seed);
show_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();


// Setup physical game map
if (create_game_map() == -1) {
	// Should never reach this clause
	show_debug_message("WARNING: map generation failed.");
	reset_map_generation();
	exit;
};

// Set up locks and keys on game map
if (create_locked_exits_and_keys() == -1) {
	// Should never reach this clause
	show_debug_message("WARNING: lock and key generation failed.");
	reset_map_generation();
	exit;
}

// Setup room references
create_room_lists();
var rooms_with_lanterns = array_create(0), rooms_with_chest_potential = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
	// Assign room reference from list
	var given_room = game_rooms[i];
	given_room.set_room_reference();
	
	if (get_random_chance_out_of(COLLECTABLE_PROBABILITY)) { given_room.add_collectables(); }
	
	// Add room to approprite room lists
	with (given_room) {
		if (get_room_reference_object_count(obj_lantern) > 0) { array_push(rooms_with_lanterns, self); has_lanterns = true; }
		if (stairs_spot_obj == -1) { array_push(rooms_with_chest_potential, self); }
	}
	
	// Add game time based on assigned room reference
	var room_difficulty = difficulty_for_room_reference(game_rooms[i].room_reference);
	var room_time_provided = TIME_PROVIDED_PER_ROOM;
	if (room_difficulty == difficulties.easy) { room_time_provided += TIME_PROVIDED_PER_EASY_ROOM; }
	if (room_difficulty == difficulties.hard) { room_time_provided += TIME_PROVIDED_PER_HARD_ROOM; }
	if (given_room.has_misleading_exits) { room_time_provided += TIME_PROVIDED_PER_DEAD_END; }
	if (given_room.has_locked_chest) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
	for (var dir = directions.up; dir < directions.stairs; dir++) {
		var given_exit = given_room.exits[dir];
		if (given_exit == -1) { continue; }
		
		if (given_exit.has_lock) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
		if (given_exit.has_illusion_walls) { room_time_provided += TIME_PROVIEDED_PER_ILLUSION_WALL; }
		if (given_exit.has_portcullis_for_room(given_room)) { room_time_provided += TIME_PROVIEDED_PER_PORTCULLIS; }
	}
	time_provided += room_time_provided;
}

// Ensure minimum number of collectables rooms exist
while (array_length(rooms_with_collectables) < MINIMUM_COLLECTABLES_ROOMS) {
	// Add collectables to random available room
	array_shuffle_ext(game_rooms);
	var new_collectables = false;
	for (var i = 0; i < array_length(game_rooms); i++;) {
		var new_collectables_room = game_rooms[i];
		new_collectables = new_collectables_room.add_collectables();
		if (new_collectables) { break; }
	}
	if (!new_collectables) {
		// Should never reach this clause
		show_debug_message("WARNING: not enough collectables rooms generated.");
		reset_map_generation();
		exit;
	}
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);
time_provided += total_number_of_rooms_with_collectables * TIME_PROVIDED_PER_COLLECTABLE;

// Ensure at least one lantern room exists
if (array_length(rooms_with_lanterns) == 0) {
	// TODO: Reroll some room reference to have lantern instead of reseting map gen
	show_debug_message("WARNING: no lantern rooms generated.");
	reset_map_generation();
	exit;
}

// Ensure at least one room with chest potential exists
if (array_length(rooms_with_chest_potential) == 0) {
	// This should NEVER happen
	show_debug_message("WARNING: no rooms with chest potential generated.");
	reset_map_generation();
	exit;
}

// Pre-light some rooms
array_shuffle_ext(rooms_with_lanterns);
for (var i = 0; i < array_length(rooms_with_lanterns); i++) {
	var given_room = rooms_with_lanterns[i];
	given_room.lit = (i == 0 || get_random_chance_out_of(PRE_LIT_PROBABILITY));
}

// Add chests to potential chest rooms
array_shuffle_ext(rooms_with_chest_potential);
for (var i = 0; i < array_length(rooms_with_chest_potential); i++) {
	var given_room = rooms_with_chest_potential[i];
	var must_spawn = (i == 0), var item_obj = (must_spawn) ? obj_map : -1;
	given_room.add_chest(must_spawn, item_obj);
}
total_items = array_length(spawned_items) + array_length(spawned_special_items);

// Add keys to account for locked chests
create_keys_for_locked_chests();

// Add portcullis and illusion walls to some rooms
for (var i = 0; i < array_length(game_rooms); i++) {
	var next_room = game_rooms[i];
	if (next_room == start_room || next_room == heart_room) { continue; }
	
	next_room.add_portcullis(); 
	next_room.add_illusion_walls();
}

// Create player object and initialize all game rooms
time_remaining = time_provided;
global.player = instance_create(-16, -16, obj_player);
for (var i = 0; i < array_length(game_rooms); i++) {
	var next_room = game_rooms[i];
	transition_to_room(next_room, false);
	initialize_room_transition_values();
}

// Transition to start room to begin game
with (global.game_manager) { sounds_to_play = array_create(0); }
play_sound(snd_torchlight, false);
transition_to_room(start_room, true);
with (global.game_manager) { array_remove(sounds_to_play, snd_win); }
