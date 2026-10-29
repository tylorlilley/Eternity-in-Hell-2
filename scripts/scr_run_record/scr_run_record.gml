/// @function RunRecord()
/// @description Everything the run being played does that the game keeps: its stats, kills and deaths as they
///	happen, then its evaluation messages and score when it ends. obj_controller holds it as run_record. It lives only
///	in memory until the run ends, after which it is saved and we add it to the save file for the run's difficulty and
/// graphics mode. Nothing is written to disk during play.
function RunRecord() constructor {
	// Which save file the run belongs in, and its number among the runs on its difficulty
	difficulty = global.difficulty;
	graphics_mode = global.graphics_mode;
	run_number = get_run_number_count(difficulty) + 1;

	// The items the player began with
	starting_left_hand_item = global.player_left_hand_item;
	starting_right_hand_item = global.player_right_hand_item;

	// What the run has done, shaped like a save file so that saving only adds it in
	stats_record = new RunModeHistoryRecord(difficulty, graphics_mode);
	stats = stats_record.stats;						// The run's stats, which the evaluation messages read as stats.name
	killers = [];									// What killed the player each time they died, in order
	rooms_looked_at_with_map_item = [];				// Rooms the player opened the map in while carrying a map
	rooms_looked_at_without_map_item = [];			// Rooms the player opened the map in without carrying a map

	// What evaluate measures when the run ends, for the evaluation messages to judge
	has_won = false;
	time_elapsed_percent = 0;
	time_remaining_percent = 0;
	collected_percent = 0;
	visited_rooms_percent = 0;
	escaped_percent = 0;
	completion_amount = 0;
	used_item_score = 0;
	final_left_hand_item = noone;
	final_right_hand_item = noone;
	had_special_swarm = false;
	map_room_count = 0;
	previous_totals = new RunModeHistoryRecord(difficulty, graphics_mode);		// The save files' totals for this difficulty from before this run

	// The evaluation, for the end screen
	evaluation_messages = [];						// The text of each message the run earned, and whether it's negative
	run_score = 0;
	is_evaluated = false;
	is_saved = false;

	/// @function increment_stat(_stat_name, [_amount])
	/// @description Adds to one of the run's stats. The name must be one RunStates defines.
	/// @param {string} _stat_name The stat to add to
	/// @param {real} [_amount] How much to add (1 by default)
	static increment_stat = function(_stat_name, _amount = 1) {
		if (!variable_struct_exists(stats, _stat_name)) {
			write_debug_message("No run stat is named " + _stat_name, debug_message_level.warning);
			return;
		}

		add_to_struct_number(stats, _stat_name, _amount);
		show_debug_message(get_debug_message_level_string(debug_message_level.eval) + ": " + _stat_name + " += " + string(_amount));
	};

	/// @function record_kill(_victim, _killer)
	/// @description Counts one thing killed or destroyed, and what did it. Killing an enemy also adds to kill_count.
	/// @param {Asset.GMObject} _victim What was killed or destroyed
	/// @param {Asset.GMObject} _killer What killed or destroyed it
	static record_kill = function(_victim, _killer) {
		add_kills_by_killer(stats_record, object_get_name(_victim), object_get_name(_killer), 1);
		if (is_enemy_object(_victim)) { increment_stat("kill_count"); }
	};

	/// @function record_death(_killer)
	/// @description Counts one death of the player and what caused it
	/// @param {Asset.GMObject} _killer What killed the player
	static record_death = function(_killer) {
		array_push(killers, _killer);
		add_to_struct_number(stats_record.deaths, object_get_name(_killer), 1);
		increment_stat("death_count");
	};

	/// @function record_map_look(_room, _is_carrying_map)
	/// @description Counts the player opening the map, and the room they opened it in the first time they do so
	///	there with or without a map in hand
	/// @param {GameRoom} _room The room the player is in
	/// @param {bool} _is_carrying_map Whether the player is carrying a map
	static record_map_look = function(_room, _is_carrying_map) {
		increment_stat("map_looks");
		var _rooms = (_is_carrying_map) ? rooms_looked_at_with_map_item : rooms_looked_at_without_map_item;
		if (array_contains(_rooms, _room)) { return; }

		array_push(_rooms, _room);
		increment_stat((_is_carrying_map) ? "rooms_map_looked_at_with_map_item" : "rooms_map_looked_at_without_map_item");
	};

	/// @function began_with_item(_item_type)
	/// @description Whether the player began the run holding an item of this type
	/// @param {Asset.GMObject} _item_type The item type
	/// @returns {bool}
	static began_with_item = function(_item_type) {
		return (starting_left_hand_item == _item_type || starting_right_hand_item == _item_type);
	};

	/// @function is_holding_item_at_end(_item_type)
	/// @description Whether the player held an item of this type when they won. Only valid once evaluate has run.
	/// @param {Asset.GMObject} _item_type The item type
	/// @returns {bool}
	static is_holding_item_at_end = function(_item_type) {
		return (final_left_hand_item == _item_type || final_right_hand_item == _item_type);
	};

	/// @function is_found_item(_item_type)
	/// @description Whether a held item is one the player found during the run: an item, but not the heart and not
	///	a type the player began with
	/// @param {Asset.GMObject} _item_type The type of the item held, or noone for an empty hand
	/// @returns {bool}
	static is_found_item = function(_item_type) {
		return (_item_type != noone && _item_type != obj_heart && !began_with_item(_item_type));
	};

	/// @function is_first_win_with_item(_item_type)
	/// @description Whether winning while holding this item is a first on this difficulty. Only valid once evaluate
	///	has run.
	/// @param {Asset.GMObject} _item_type The type of the item held, or noone for an empty hand
	/// @returns {bool} False for an empty hand or the heart
	static is_first_win_with_item = function(_item_type) {
		if (_item_type == noone || _item_type == obj_heart) { return false; }

		return (get_struct_number(previous_totals.item_wins, object_get_name(_item_type)) == 0);
	};

	/// @function has_novel_death()
	/// @description Whether anything that killed the player this run had never killed them before on this
	///	difficulty. Only valid once evaluate has run.
	/// @returns {bool}
	static has_novel_death = function() {
		for (var _i = 0; _i < array_length(killers); _i++) {
			if (get_struct_number(previous_totals.deaths, object_get_name(killers[_i])) == 0) { return true; }
		}

		return false;
	};

	/// @function evaluate()
	/// @description Judges the run once it's won or lost: measures it, then goes through every evaluation message in
	///	order, keeping the ones it earned (every one, in test mode) and adding up their scores, clamped to 0-100. Each
	///	message's test runs as a method of this run, so it reads the run directly (see EvaluationMessage).
	static evaluate = function() {
		var _controller = global.controller, _time_provided = _controller.time_provided, _time_remaining = _controller.final_time_remaining;

		// Measure the run
		has_won = is_game_won();
		time_elapsed_percent = 100 * (_time_provided - _time_remaining) / _time_provided;
		time_remaining_percent = 100 * _time_remaining / _time_provided;
		collected_percent = get_collectables_score();
		visited_rooms_percent = get_mapped_rooms_score();
		escaped_percent = get_victory_amount_score();
		completion_amount = _controller.completion_amount;
		used_item_score = get_used_item_score();
		final_left_hand_item = _controller.final_player_left_hand_item;
		final_right_hand_item = _controller.final_player_right_hand_item;
		had_special_swarm = (_controller.same_skeleton_type != noone);
		map_room_count = array_length(_controller.game_rooms);
		previous_totals = get_stats_record_total(difficulty);

		// Judge it
		var _messages = get_evaluation_messages();
		evaluation_messages = [];
		run_score = 0;
		for (var _i = 0; _i < array_length(_messages); _i++) {
			var _message = _messages[_i], _is_earned = method(self, _message.is_earned);
			if (!global.is_test_mode && !_is_earned()) { continue; }

			run_score += get_message_score(_message);
			array_push(evaluation_messages, [get_message_text(_message), _message.is_negative]);
			if (_message.is_achievement) { stats_record.evaluation_messages[$ _message.title] = 1; }
		}
		run_score = clamp(run_score, 0, 100);
		is_evaluated = true;
	};

	/// @function get_message_score(_message)
	/// @description What an evaluation message adds to this run's score
	/// @param {struct} _message The EvaluationMessage
	/// @returns {real}
	static get_message_score = function(_message) {
		if (!is_method(_message.score_value)) { return _message.score_value; }

		var _get_score = method(self, _message.score_value);
		return _get_score();
	};

	/// @function get_message_text(_message)
	/// @description The text an evaluation message shows for this run: its title, or a score line's measure of the run
	/// @param {struct} _message The EvaluationMessage
	/// @returns {string}
	static get_message_text = function(_message) {
		if (_message.is_achievement) { return _message.title; }

		var _get_text = method(self, _message.get_text);
		return _get_text();
	};

	/// @function save()
	/// @description Ends the run's record: adds the outcome (a win, or a loss to the last thing that killed the
	///	player), logs it, and adds the whole record to the save file for the run's difficulty and graphics mode.
	///	Runs in test mode are logged but not saved. Call it once the run is over, after evaluate unless the player
	///	gave up; later calls do nothing.
	static save = function() {
		if (is_saved) { return; }

		is_saved = true;

		// Add the outcome
		var _controller = global.controller, _has_won = is_game_won(), _death_count = array_length(killers), _outcome = "lost";
		stats_record.runs = 1;
		stats_record.wins = (_has_won) ? 1 : 0;
		stats_record.best_score = run_score;
		if (!_has_won && _death_count > 0) { stats_record.last_death_run_numbers[$ object_get_name(killers[_death_count - 1])] = run_number; }
		if (_has_won) {
			_outcome = "won";
			var _final_items = [_controller.final_player_right_hand_item, _controller.final_player_left_hand_item], _hand_names = ["right hand", "left hand"];
			for (var _i = 0; _i < array_length(_final_items); _i++) {
				var _item_type = _final_items[_i];
				if (_item_type == noone) { continue; }

				_outcome += "; " + _hand_names[_i] + ": " + object_get_name(_item_type);
				if (_item_type != obj_heart) { stats_record.item_wins[$ object_get_name(_item_type)] = 1; }
			}
		}

		// Log it
		for (var _i = 0; _i < _death_count; _i++) { update_log("killed_by", object_get_name(killers[_i])); }
		if (is_evaluated) { update_log("score", run_score); }
		update_log("outcome", _outcome);
		if (global.is_test_mode) { return; }

		// Save it
		add_stats_record(get_saved_stats_record(difficulty, graphics_mode), stats_record);
		write_saved_stats_record(difficulty, graphics_mode);
	};
}

/// @function get_run_record()
/// @description The record of the run being played
/// @returns {struct|undefined} Its RunRecord, or undefined when no run is being played
function get_run_record() {
	var _controller = global.controller;
	return (is_existing_instance(_controller)) ? _controller.run_record : undefined;
}

/// @function increment_run_stat(_stat_name, [_amount])
/// @description Adds to one of the run's stats, from anywhere in the game. The name must be one RunStats
///	defines. Does nothing when no run is being played.
/// @param {string} _stat_name The stat to add to
/// @param {real} [_amount] How much to add (1 by default)
function increment_run_stat(_stat_name, _amount = 1) {
	var _run_record = get_run_record();
	if (!is_undefined(_run_record)) { _run_record.increment_stat(_stat_name, _amount); }
}

/// @function record_run_kill(_victim, _killer)
/// @description Counts one thing the run killed or destroyed and what did it. The title screen's death log shows the
///	kills whose killer is_player_killer says was the player's doing. Enemy kills also count toward kill_count (see
///	is_enemy_object). An enemy killed by another enemy's projectile isn't recorded, as no player action caused it.
/// @param {Asset.GMObject} _victim What was killed or destroyed
/// @param {Asset.GMObject} _killer What killed or destroyed it
function record_run_kill(_victim, _killer) {
	var _run_record = get_run_record();
	if (!is_undefined(_run_record)) { _run_record.record_kill(_victim, _killer); }
}

/// @function record_run_death(_killer)
/// @description Counts one death of the player and what caused it. The last death of a lost run marks its killer
///	with the run's number when the run is saved.
/// @param {Asset.GMObject} _killer What killed the player: obj_controller for running out of time, obj_mirror for
///	running out of time in the hall of mirrors, and obj_player for restarting from the pause menu
function record_run_death(_killer) {
	var _run_record = get_run_record();
	if (!is_undefined(_run_record)) { _run_record.record_death(_killer); }
}

/// @function is_enemy_object(_object_index)
/// @description Whether killing an object of this type counts as killing an enemy: any child of obj_enemy, and the
///	living block and giant eye, which attack the player without being children of obj_enemy. Doors, chests,
///	statues and the player aren't enemies.
/// @param {Asset.GMObject} _object_index The object type
/// @returns {bool}
function is_enemy_object(_object_index) {
	return (_object_index == obj_living_block || _object_index == obj_giant_eye || object_is_ancestor(_object_index, obj_enemy));
}

/// @function is_player_killer(_object_index)
/// @description Whether a kill credited to this killer was the player's doing, for the death log's kill column. The
///	player is credited for a sword in their hand, a living block they pushed into lava, a phantom banished when their
///	torch lit the last lantern, a giant eye they spun until it died, and giving up from the pause menu. A block only
///	crushes when the player pushes it, special meat is bait the player left, and a bomb is only credited when the
///	player set it off. Lava, the giant worm and an enemy's sword aren't the player's doing.
/// @param {Asset.GMObject} _object_index The killer
/// @returns {bool}
function is_player_killer(_object_index) {
	return (_object_index == obj_player || _object_index == obj_block || _object_index == obj_meat || _object_index == obj_bomb);
}
