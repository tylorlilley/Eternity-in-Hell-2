// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.is_farm_mode) { sprite_prefetch(spr_player_farmer); }

// Initialize global values
random_set_seed(global.seed);
show_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();


// Setup room references
if (create_game_map() == -1) {
	// Should never reach this clause
	show_debug_message("WARNING: map generation failed.");
	reset_map_generation();
	exit;
};
create_room_lists();
current_room = start_room;
var item_spawned = false, rooms_with_lanterns = array_create(0), rooms_without_stairs_spot_obj = array_create(0);
for (var i = 0; i < array_length(game_rooms); i++) {
	// Assign room reference from list
	var given_room = game_rooms[i];
	given_room.set_room_reference();
	given_room.initialize_room();
   
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
	if (given_room.has_collectables) { room_time_provided += TIME_PROVIDED_PER_COLLECTABLE; }
	if (given_room.misleading_room) { room_time_provided += TIME_PROVIDED_PER_DEAD_END; }
	for (var dir = directions.up; dir < directions.stairs; dir++) {
		var given_exit = given_room.exits[dir];
		if (given_exit != -1 && given_exit.has_lock) { room_time_provided += TIME_PROVIEDED_PER_LOCK; }
	}
	time_provided += room_time_provided;
}

// Ensure minimum number of collectables rooms exist
/*
while (array_length(rooms_with_collectables) < MINIMUM_COLLECTABLES_ROOMS) {
	var new_collectables = -1;
	array_shuffle(game_rooms);
	for (var i = 0; i < array_length(game_rooms); i++) {
		var new_collectables_room = game_rooms[i];
		new_collectables_room.add_collectables();
		if (new_collectables != -1) { break; }
	}
	if (new_collectables == -1) {
		// Should never reach this clause
		show_debug_message("WARNING: not enough collectables rooms generated.");
		reset_map_generation();
		exit;
	}
	new_collectables_room.add_collectables();
	time_provided += TIME_PROVIDED_PER_COLLECTABLE;
	array_push(rooms_with_collectables, new_collectables_room);
}
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);
*/

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


