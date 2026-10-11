// Play every sound queued by play_sound this step, each only once however many times it was queued
sounds_to_play = array_unique(sounds_to_play);
while (array_length(sounds_to_play) > 0) {
	var _sound_to_play = array_pop(sounds_to_play);
	audio_play_sound(_sound_to_play, 10, false);
}

// In seed testing mode, once the current seed's game is running (see obj_controller's End Step), end that game and start
// one with the next seed, which is saved as the last seed. Testing stops when the seed reaches MAX_SEED.
if (global.is_test_mode && global.is_seed_testing_mode && global.has_seed_test_passed) {
	global.has_seed_test_passed = false;
	with (obj_controller) { restart_game(); }
	global.seed++;
	update_setting("last_seed", global.seed);
	write_debug_message("TRY SEED - " + string(global.seed));
	if global.seed == MAX_SEED { write_debug_message("ALL SEEDS CLEARED"); }
	else { room_goto(rm_start); }
}