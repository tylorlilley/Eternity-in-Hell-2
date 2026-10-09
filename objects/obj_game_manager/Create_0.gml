singleton_instance();
initialize_shader_pointers();
audio_group_load(audiogroup_default);
gameframe_init();

global.datetime = string(current_day) + "-" + string(current_month) + "-" + string(current_year) + ":" + string(current_hour) + ":" + string(current_minute);
depth = 10000;

key_up = false;
key_down = false;
key_left = false;
key_right = false;
key_shift = false;

clear_inputs_for_next_frame();

paused = false;
number_of_frames_since_game_began = 0;
sounds_to_play = [];
global.game_manager = id;