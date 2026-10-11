// The game manager persists between rooms, so a copy made when a room holding one is entered again destroys itself
singleton_instance();
// Look up the sprite shader's uniform handles, load the default audio group and set up the GameFrame window frame
initialize_shader_pointers();
audio_group_load(audiogroup_default);
gameframe_init();

// The date and time the app started, which stamps the lines added to the log until a new game resets it (see update_log)
global.datetime = string(current_day) + "-" + string(current_month) + "-" + string(current_year) + ":" + string(current_hour) + ":" + string(current_minute);
// Behind every other instance, so what it draws in its Draw Begin event lies under everything else
depth = 10000;

// No direction keys or shift held yet. They are set before the inputs are cleared, which copies them to their prev_key
// variables
key_up = false;
key_down = false;
key_left = false;
key_right = false;
key_shift = false;

clear_inputs_for_next_frame();

paused = false;
number_of_frames_since_game_began = 0;		// Counts frames, so the game can tell which ones to process
sounds_to_play = [];						// Sounds queued by play_sound, which the end step plays
global.game_manager = id;					// Shortcut to the game manager for the rest of the game