// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
if (global.graphics_mode == graphics_modes.farmer) { sprite_prefetch(spr_player_farmer); }
grid_update_timer = 0;
player_appear_timer = 0;
flash_obj = noone;
dropped_meat = [];
global.datetime = string(current_day) + "-" + string(current_month) + "-" + string(current_year) + ":" + string(current_hour) + ":" + string(current_minute);
depth = -9999;

global.shuffled_item_sprites = array_shuffle(global.item_sprites);
global.shuffled_regular_enemy_sprites = array_shuffle(global.regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_shuffle(global.rotational_enemy_sprites);

// Initialize global values
random_set_seed(global.seed);
write_debug_message("SEED: "+string(random_get_seed()));
initialize_game_variables();

// Plan the whole map: its rooms, layouts, contents, locks and keys, score and time (scr_game_map)
var _map = generate_map();
game_rooms = _map.rooms;
start_room = _map.start_room;
heart_room = _map.heart_room;
same_skeleton_type = _map.same_skeleton_type;
spawned_items = _map.spawned_items;
spawned_special_items = _map.spawned_special_items;
time_provided = _map.time_provided;
time_remaining = time_provided;

// Build every room, which leaves the controller in the last room built. Building takes the collectables from a room with
// no space for them, so the rooms with collectables are taken after
_map.build_rooms();
rooms_with_collectables = _map.rooms_with_collectables;
total_number_of_rooms_with_collectables = array_length(rooms_with_collectables);

// Transition to start room to begin game
with (global.game_manager) { 
	number_of_frames_since_game_began = 0;
	sounds_to_play = [];
	clear_inputs_for_next_frame();
	paused = false;
}
play_sound(snd_torchlight, false);
global.player = instance_create(-16, -16, obj_player);
transition_to_room(start_room);
player_appear_timer = 0;
global.player.visible = true;
with (global.game_manager) { array_remove_first(sounds_to_play, snd_win); }

update_log("run_number", run_record.run_number);
update_log("SEED", global.seed);
update_log("DIFFICULTY", get_difficulty_string(global.difficulty));
update_log("VERSION", GM_version);

write_debug_message("Total rooms generated: " + string(array_length(game_rooms)));
if (current_room.is_special_room) { write_debug_message("START ROOM IS SPECIAL ROOM"); }
