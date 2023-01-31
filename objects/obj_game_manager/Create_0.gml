singleton_instance();
initialize_shader_pointers();
audio_group_load(audiogroup_default);

FRAMES_TO_WAIT_BEFORE_PROCESSING = 6;
number_of_frames_since_game_began = 0;
sounds_to_play = array_create(0);
global.game_manager = id;