// Read the evaluation traits from file and print them to the debug console (nothing keeps them)
var _trait_manager = new EvaluationTraitManager();
with (_trait_manager) {
	read_traits_from_file();
	show_debug_message(evaluation_traits);
}
// Update the graphics textures: clear video memory's texture pages, then preload the player and collectable sprites
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.graphics_mode == graphics_modes.farmer) { sprite_prefetch(spr_player_farmer); }
grid_update_timer = 0;		// Steps until the current room's path grids are rebuilt, when a rebuild is due
player_appear_timer = 0;	// Steps until the player appears again after being hidden by stairs or a respawn
flash_obj = noone;			// The instance whose screen flash is showing, if any
dropped_meat = [];			// Meat the player has put down, newest last
// The date and time this run started, which stamps the lines the run adds to the log (see update_log)
global.datetime = string(current_day) + "-" + string(current_month) + "-" + string(current_year) + ":" + string(current_hour) + ":" + string(current_minute);
depth = -9999;				// Draw in front of nearly every other instance

// Shuffle which item and enemy sprites stand in for which, for the unknown graphics mode (see get_sprite_to_use)
global.shuffled_item_sprites = array_get_duplicate(global.item_sprites);
global.shuffled_regular_enemy_sprites = array_get_duplicate(global.regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_get_duplicate(global.rotational_enemy_sprites);
global.shuffled_item_sprites = array_shuffle(global.shuffled_item_sprites);
global.shuffled_regular_enemy_sprites = array_shuffle(global.shuffled_regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_shuffle(global.shuffled_rotational_enemy_sprites);

// Seed the random number generator with the game's seed, then set up the display and the controller's game state
random_set_seed(global.seed);
write_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();

// Plan the whole map: its rooms, layouts, contents, locks and keys, difficulty score and time (see generate_map)
var _map = generate_map();
game_rooms = _map.rooms;
start_room = _map.start_room;
heart_room = _map.heart_room;
current_room = start_room;
same_skeleton_type = _map.same_skeleton_type;
rooms_with_collectables = _map.rooms_with_collectables;
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);
spawned_items = _map.spawned_items;
spawned_special_items = _map.spawned_special_items;
time_provided = _map.time_provided;

// Set the clock to the full time, then visit every room once without the player to create its instances
time_remaining = time_provided;
for (var _i = 0; _i < array_length(game_rooms); _i++) {
	var _next_room = game_rooms[_i];
	transition_to_room(_next_room, false);
	initialize_room_transition_values();
}

// Reset the game manager for a new game, then create the player and bring them into the start room
with (global.game_manager) { 
	number_of_frames_since_game_began = 0;
	sounds_to_play = [];
	clear_inputs_for_next_frame();
	paused = false;
	update_run_number_log(global.difficulty);
}
play_sound(snd_torchlight, false);
global.player = instance_create(-16, -16, obj_player);
transition_to_room(start_room, true);
// Arriving at the start counts as a respawn: show the player at once, and drop the respawn's win sound
player_appear_timer = 0;
global.player.visible = true;
with (global.game_manager) { array_remove_first(sounds_to_play, snd_win); }

update_log("SEED", global.seed);
update_log("DIFFICULTY", get_difficulty_string(global.difficulty));
update_log("VERSION", GM_version);

write_debug_message("Total rooms generated: " + string(array_length(game_rooms)));
if (current_room.is_special_room) { write_debug_message("START ROOM IS SPECIAL ROOM"); }
