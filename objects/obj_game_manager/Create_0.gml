singleton_instance();
initialize_shader_pointers();
audio_group_load(audiogroup_default);
gameframe_init();

depth = -10000;

key_up = false;
key_down = false;
key_left = false;
key_right = false;

clear_inputs_for_next_frame();

paused = false;
escaped = false;
number_of_frames_since_game_began = 0;
sounds_to_play = array_create(0);
global.game_manager = id;