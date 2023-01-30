singleton_instance();
initialize_shader_pointers();
audio_group_load(audiogroup_default);

sounds_to_play = array_create(0);
global.sound_manager = id;