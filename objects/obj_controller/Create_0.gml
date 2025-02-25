// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.graphics_mode == graphics_modes.farmer) { sprite_prefetch(spr_player_farmer); }
grid_update_timer = 0;
player_appear_timer = 0;
flash_obj = noone;
dropped_meat = array_create(0);
global.datetime = string(current_day) + "-" + string(current_month) + "-" + string(current_year) + ":" + string(current_hour) + ":" + string(current_minute);
depth = -9999;

global.shuffled_item_sprites = array_get_duplicate(global.item_sprites);
global.shuffled_regular_enemy_sprites = array_get_duplicate(global.regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_get_duplicate(global.rotational_enemy_sprites);
global.shuffled_item_sprites = array_shuffle(global.shuffled_item_sprites);
global.shuffled_regular_enemy_sprites = array_shuffle(global.shuffled_regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_shuffle(global.shuffled_rotational_enemy_sprites);

// Initialize global values
random_set_seed(global.seed);
write_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();
create_room_lists();

// Setup physical game map
if (create_game_map() == -1) {
	// Should never reach this clause
	write_debug_message("Map generation failed.", "WARNING");
	reset_map_generation();
	exit;
};

// Setup room references
var rooms_with_lanterns = array_create(0), rooms_with_chest_potential = array_create(0), lit_rooms = array_create(0), spawned_special_rooms = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
	var given_room = game_rooms[i];
	
	// Add collectables and special room references to some rooms
	if (get_random_chance_out_of(COLLECTABLE_PROBABILITY)) { given_room.add_collectables(); }
	if (array_length(spawned_special_rooms) < SPECIAL_ROOM_LIMIT && get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { given_room.assign_room_ref(false, true); }
	
	// Add room to approprite room lists
	with (given_room) {
		if (lit) { array_push(lit_rooms, self); }
		if (has_lanterns) { array_push(rooms_with_lanterns, self); }
		if (is_special_room) { array_push(spawned_special_rooms, self); }
		if (stairs_spot_obj == -1) { array_push(rooms_with_chest_potential, self); }
	}
}

// Ensure minimum number of collectables rooms exist
var minimum_collectables_rooms = ceil(array_length(game_rooms)/4)+1;
while (array_length(rooms_with_collectables) < minimum_collectables_rooms) {
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
		write_debug_message("Not enough collectables rooms generated.", "WARNING");
		reset_map_generation();
		exit;
	}
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);
time_provided += total_number_of_rooms_with_collectables * TIME_PROVIDED_PER_COLLECTABLE;

// Ensure at least one lantern room exists
if (array_length(rooms_with_lanterns) == 0) {
	var random_room = array_random_get(game_rooms);
	with (random_room) {
		assign_room_ref(true, false);
		if (has_lanterns) { array_push(rooms_with_lanterns, self); }
	}
	if (!random_room.has_lanterns && !global.is_test_mode) {
		// This should NEVER happen
		write_debug_message("No lantern rooms generated.", "WARNING");
		reset_map_generation();
		exit;
	}
}

// Pre-light some lantern rooms, with at least one pre-lit
if (array_length(lit_rooms) == 0) { 
	var random_lantern_room = array_random_get(rooms_with_lanterns);
	with (random_lantern_room) {
		if (!has_lanterns) { write_debug_message("Room without lanterns in lantern room list: " + room_get_name(room_reference), "WARNING"); }
		lit = true;
		has_phantom = false;
	}
}

// Ensure at least one room with chest potential exists
if (array_length(rooms_with_chest_potential) == 0) {
	// This should NEVER happen
	write_debug_message("No rooms with chest potential generated.", "WARNING");
	reset_map_generation();
	exit;
}

// Add chests to potential chest rooms
array_shuffle_ext(rooms_with_chest_potential);
for (var i = 0; i < array_length(rooms_with_chest_potential); i++) {
	var given_room = rooms_with_chest_potential[i];
	var must_spawn = (i == 0), item_obj = -1;
	if (must_spawn) {
		// Determine the guarenteed spawn item type
		var use_easy_difficulty = global.difficulty == difficulties.easy;
		var spawn_with_map = (global.player_right_hand_item == obj_map || global.player_left_hand_item == obj_map);
		var spawn_with_compass = (global.player_right_hand_item == obj_compass || global.player_left_hand_item == obj_compass)
		var item_obj = obj_torch
		if (spawn_with_map && spawn_with_compass) { item_obj = obj_torch}
		else if (spawn_with_compass) { item_obj = obj_map; }
		else if (spawn_with_map) { item_obj = (use_easy_difficulty) ? obj_torch : obj_compass; }
		else if (use_easy_difficulty) { item_obj = obj_map; }
		else { item_obj = get_coin_flip() ? obj_map : obj_compass; }
	}

	given_room.add_chest(must_spawn, item_obj);
}

// Set up locks and keys on game map
if (create_locked_exits_and_keys() == -1) {
	// Should never reach this clause
	write_debug_message("Lock and key generation failed.", "WARNING");
	reset_map_generation();
	exit;
}

// Add special exit types to some rooms
for (var i = 0; i < array_length(game_rooms); i++) {
	var next_room = game_rooms[i];
	if (next_room == start_room || next_room == heart_room) { continue; }
	if (next_room.has_no_cardinal_exits || next_room.is_connected_to_hall_of_mirrors()) { continue; }
	
	next_room.add_illusion_walls();
	next_room.add_portcullis(); 
	next_room.add_unlocked_doors();
}


// Add more rooms based on difficulty
add_rooms_to_reach_target_difficulty();

// Add time for rooms
for (var i = 0; i < array_length(game_rooms); i++) {
	// Add game time based on assigned room reference
	//var room_difficulty = difficulty_for_room_reference(game_rooms[i].room_reference);
	//var room_time_provided = TIME_PROVIDED_PER_ROOM;
	//if (room_difficulty == difficulties.easy) { room_time_provided += TIME_PROVIDED_PER_EASY_ROOM; }
	//if (room_difficulty == difficulties.hard) { room_time_provided += TIME_PROVIDED_PER_HARD_ROOM; }
	//if (given_room.has_misleading_exits) { room_time_provided += TIME_PROVIDED_PER_DEAD_END; }
	//if (given_room.has_locked_chest) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
	var reference_difficulty = game_rooms[i].room_reference_difficulty;
	if (reference_difficulty < 0 ) { reference_difficulty = 0; }
	var room_time_provided = TIME_PROVIDED_PER_ROOM * (reference_difficulty / AVERAGE_ROOM_DIFFICULTY);
	if (room_time_provided < 15) { room_time_provided = 15; }
	for (var dir = directions.up; dir < directions.stairs; dir++) {
		var given_exit = given_room.exits[dir];
		if (given_exit == -1) { continue; }
		
		if (given_exit.has_lock) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
		if (given_exit.has_illusion_walls > 0) { room_time_provided += TIME_PROVIEDED_PER_ILLUSION_WALL; }
		if (given_exit.has_closed_portcullis_for_room(given_room)) { room_time_provided += TIME_PROVIEDED_PER_PORTCULLIS; }
	}
	time_provided += room_time_provided;
}

// Create player object and initialize all game rooms
time_remaining = time_provided;
for (var i = 0; i < array_length(game_rooms); i++) {
	var next_room = game_rooms[i];
	transition_to_room(next_room, false);
	initialize_room_transition_values();
}

// Transition to start room to begin game
with (global.game_manager) { 
	number_of_frames_since_game_began = 0;
	sounds_to_play = array_create(0);
	clear_inputs_for_next_frame();
	paused = false;
}
play_sound(snd_torchlight, false);
global.player = instance_create(-16, -16, obj_player);
transition_to_room(start_room, true);
player_appear_timer = 0;
global.player.visible = true;
with (global.game_manager) { array_remove(sounds_to_play, snd_win); }


update_log("SEED", global.seed);
update_log("DIFFICULTY", get_difficulty_string(global.difficulty));
update_log("VERSION", GM_version);

write_debug_message("Total rooms generated: " + string(array_length(game_rooms)));
