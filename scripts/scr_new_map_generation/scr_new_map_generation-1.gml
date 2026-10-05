// Map generation's entry point. A GameMap generates itself step by step (see scr_game_map); its rooms (scr_room),
// exits (scr_exit), layouts (scr_room_layout) and sins (scr_sin) each handle their own part.

/// @function mapgen_generate()
/// @description Creates a whole map for global.difficulty
/// @returns {GameMap} The finished map
function mapgen_generate() {
	// Generate maps up to 100 times before giving up. It should always work on the first try, this is here as a failsafe.
	// As a failsafe, switch to the next seed after 100 failures and try again.
	var _map = undefined;
	while (is_undefined(_map)) {
		// Attempt map generation on this seed up to 100 times
		var _failed_attempts = 0;
		do {
			_failed_attempts += 1;

			// Step 1: create initial map using cached version of room layouts read from disk, then try steps 2 to 13 on it
			_map = new GameMap();
			if (!_map.try_generate()) { _map = undefined; }
		}
		until (!is_undefined(_map) || _failed_attempts >= 100);

		// If map is still undefined give up and move on to next seed
		if (is_undefined(_map)) {
			write_debug_message("Map generation failed 100 times for seed: " + string(global.seed), "ERROR");
			global.seed += 1;
			random_set_seed(global.seed);
		}
	}

	// Once map generation has succeeded, deal with the starting hand items
	var _hands_seed = irandom(MAX_SEED), _build_seed = irandom(MAX_SEED);
	random_set_seed(_hands_seed);
	_map.adjust_items_for_hands();
	random_set_seed(_build_seed);

	_map.calculate_collectables_and_items_lists();
	return _map;
}