// Update game graphics textures
var trait_manager = new EvaluationTraitManager();
with (trait_manager) {
	read_traits_from_file();
	show_debug_message(evaluation_traits);
}
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

// Plan the whole map: its rooms, layouts, contents, locks and keys, score and time (scr_map_generation)
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
	update_run_number_log(global.difficulty);
}
play_sound(snd_torchlight, false);
global.player = instance_create(-16, -16, obj_player);
transition_to_room(start_room, true);
player_appear_timer = 0;
global.player.visible = true;
with (global.game_manager) { array_remove_first(sounds_to_play, snd_win); }

update_log("SEED", global.seed);
update_log("DIFFICULTY", get_difficulty_string(global.difficulty));
update_log("VERSION", GM_version);

write_debug_message("Total rooms generated: " + string(array_length(game_rooms)));
if (current_room.is_special_room) { write_debug_message("START ROOM IS SPECIAL ROOM"); }
