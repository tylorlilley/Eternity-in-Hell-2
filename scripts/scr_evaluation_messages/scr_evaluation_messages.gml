function EvaluationMessageManager() constructor {
	evaluation_messages = array_create(0);
	current_score = 0;
	
	// Item Usage
	death_count = 0;
	rosary_use_count = 0;
	staff_blocked_fireballs = 0;
	staff_blocked_beams = 0;
	holes_dug = 0;
	bombs_lit = 0;
	bombs_lit_by_fireball = 0;
	torches_lit = 0;
	torches_lit_by_fireball = 0;
	rooms_lit = 0;
	clock_time_saved = 0;
	map_looks = 0;
	map_looks_with_map_item = 0;
	special_torches_lit = 0;
	used_item_types = 0;
	used_special_items = 0;
	
	// Kills
	kill_count = 0;
	kill_after_death_count = 0;
	worm_kill_count = 0;
	sword_kill_count = 0;
	block_kill_count = 0;
	nose_block_kill_count = 0;
	double_block_kill_count = 0;
	fireball_kill_count = 0;
	meat_kill_count = 0;
	lava_kill_count = 0;
	
	// Misc.
	item_lava_count = 0;
	decapitated_corpses = 0;
	spontaneously_exploded_enemy = 0;
	dual_wielded_items = 0;
	dual_wielded_lit_torches = 0;
	mirror_bounced_projectile = 0;
	blocks_pushed_into_lava = 0;
	
	// Chests
	chests_opened = 0;
	chests_opened_lit_bombs = 0;
	trapped_chests_opened = 0;
	trapped_chests_destroyed = 0;
	unlocked_chests = 0;
	
	// Doors and Exits
	opened_doors = 0;
	unlocked_doors = 0;
	portcullises_opened = 0;
	illusion_walls_discovered = 0;
	
	// Tiles
	crushed_bugs = 0;
	times_infected = 0;
	rustled_bushes = 0;
	disturbed_bones = 0;
	
	// Special Rooms
	giant_eye_room_visited = 0;
	giant_eye_room_solved = 0;
	gudetama_room_visited = 0;
	gudetama_room_solved = 0;
	hall_of_mirrors_room_visited = 0;
	hall_of_mirrors_room_solved = 0;
	red_chest_room_visited = 0;
	red_chest_room_solved = 0;
	special_heart_victory = 0;
	inverted_cross_room_visited = 0;
	inverted_cross_room_solved = 0;
	
	/// @function									increment_evaluation_variable(must_have_lantern, spawn_special_room);
	/// @param		{string} var_name				A string representing the evaluation varibale name
	/// @param		{int} value						OPTIONAL: the value to increment by
	function increment_evaluation_variable(var_name, value = 1) {
		if (variable_struct_exists(self, var_name)) {
			var current_value = variable_struct_get(self, var_name);
			variable_struct_set(self, var_name, current_value + value);
			write_debug_message(var_name + " += " + string(value), "Eval");
		}
		else {
			write_debug_message("Non-existent evaluation variable referenced.", "WARNING");
		}
	}
	
	/// @function									calculate_evaluation_messages_and_score();
	function calculate_evaluation_messages_and_score() {
		var controller = global.controller;
		evaluation_messages = array_create(0);
		current_score = 0;
		
		var has_won = is_game_won(), has_lost = is_game_lost();
		var time_elapsed = (global.is_test_mode) ? 0 : (controller.time_provided - controller.final_time_remaining);
		var time_remaining = (global.is_test_mode) ? 0 : controller.final_time_remaining;
		var time_provided = (global.is_test_mode) ? 0 : controller.time_provided;
		// var time_elapsed_string = "Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(time_elapsed, 60)), 2);
		// var time_remaining_string = "Extra Time Remaining: "+string(floor(time_remaining/(60)))+":"+get_zero_padded_string(floor(modulo(time_remaining, 60)), 2);
		var time_elapsed_string = "Time Elapsed: "+get_percentage_string((time_elapsed/time_provided));
		var time_remaining_string = "Extra Time Remaining: "+get_percentage_string((time_remaining/time_provided));
		
		// Main Scoring Messages
		add_evaluation_message(true, time_elapsed_string, false, 0);
		add_evaluation_message(true, "Collected: "+get_percentage_string(get_collectables_score()), false, get_collectables_score()/3);
		add_evaluation_message(true, "Visited Rooms: "+get_percentage_string(get_mapped_rooms_score()), false, get_mapped_rooms_score()/3);
		add_evaluation_message((global.is_test_mode || controller.completion_amount > 0), "Escaped Amount: "+get_percentage_string(get_victory_amount_score()), false, get_victory_amount_score()/10);
		add_evaluation_message((global.is_test_mode || has_won), time_remaining_string, false, get_time_remaining_score()/10);
		add_evaluation_message((global.is_test_mode ||((has_won && death_count > 0) || (has_lost && death_count > 1))), "Death Penalty: "+string(death_count-1), true, death_count*-5);
		add_evaluation_message((global.is_test_mode || (controller.killed_by != noone && get_death_count(controller.killed_by, global.difficulty) == 0)), "Novel Death", true, 0);
		add_evaluation_message((global.is_test_mode || kill_count > 0), "Killed Enemies: "+string(kill_count), false, kill_count);
		add_evaluation_message((global.is_test_mode || used_special_items > 0), "Cursed Items Used : "+string(used_special_items), true, used_special_items*-10);
		
		// Item Scoring messages
		add_evaluation_message((global.is_test_mode || get_used_item_score() > 0), "Resourceful", false, get_used_item_score());
		add_evaluation_message((global.is_test_mode || (has_won && global.player_left_hand_item == noone && global.player_right_hand_item == noone)), "Courageous Preparation", false, 10);
		add_evaluation_message((global.player_left_hand_item != noone && global.player_right_hand_item != noone), "Overprepared", true, -5);
		add_evaluation_message((global.is_test_mode || (has_won && (controller.final_player_left_hand_item == noone || controller.final_player_right_hand_item == noone))), "Returned Empty-Handed", true, -5);
		if (global.is_test_mode || (has_won && (controller.final_player_right_hand_item != global.player_left_hand_item && controller.final_player_right_hand_item != global.player_right_hand_item && controller.final_player_right_hand_item != obj_heart))) {
			add_evaluation_message((true), "Returned with a Memento", false, 5);
		}
		else if ((global.is_test_mode || (has_won && (controller.final_player_left_hand_item != global.player_left_hand_item && controller.final_player_left_hand_item != global.player_right_hand_item && controller.final_player_left_hand_item != obj_heart)))) {
			add_evaluation_message((true), "Returned with a Memento", false, 5);
		}
		if (global.is_test_mode || (has_won && controller.final_player_left_hand_item != obj_heart && get_item_win_count(controller.final_player_left_hand_item, global.difficulty) == 0)) {
			add_evaluation_message((true), "New Item Recovered", false, 0);
		}
		else if (global.is_test_mode || (has_won && controller.final_player_right_hand_item != obj_heart && get_item_win_count(controller.final_player_right_hand_item, global.difficulty) == 0)) {
			add_evaluation_message((true), "New Item Recovered", false, 0);
		}
		
		// Item Mastery Bonuses
		add_evaluation_message((sword_kill_count >= 3), "Sword Master", false, 5);
		add_evaluation_message((rosary_use_count >= 3), "Devoted Follower", false, 5);
		add_evaluation_message(((unlocked_doors + unlocked_chests) >= 5), "Master Lockpicker", false, 5);
		add_evaluation_message((holes_dug >= 6), "Tunnel Digger", false, 5);
		add_evaluation_message((meat_kill_count >= 3), "Expert Poisoner", false, 5);
		add_evaluation_message((clock_time_saved >= 600), "Time Saver", false, 5);
		add_evaluation_message((special_torches_lit > 0 || dual_wielded_lit_torches > 0), "Shone Brightly", false, 5);
		add_evaluation_message((map_looks_with_map_item >= MAX_NUMBER_OF_ROOMS/2 && (map_looks - map_looks_with_map_item) < MAX_NUMBER_OF_ROOMS/2), "Consulter of Maps", false, 5);
		add_evaluation_message(((map_looks - map_looks_with_map_item) >= MAX_NUMBER_OF_ROOMS/2), "Map Overreliance", true, -2);
		
		// Misc Bonuses
		add_evaluation_message((chests_opened >= 5), "Treasure Hunter", false, 2);
		add_evaluation_message((kill_count >= 10), "Monster Slayer", false, 2);
		//add_evaluation_message((lava_kill_count > 0), "Accidental Kill", false, 2);
		add_evaluation_message((kill_after_death_count >= 1), "Posthumous Revenge", false, 2);
		add_evaluation_message((fireball_kill_count > 0), "Friendly Fire", false, 2);
		add_evaluation_message((worm_kill_count > 0), "Accidental Kill", false, 2);
		add_evaluation_message((block_kill_count >= 4), "Bulldozer", false, 2);
		add_evaluation_message((double_block_kill_count >= 1), "Two Birds One Block", false, 5);
		add_evaluation_message((nose_block_kill_count >= 1), "Bulldozed in Lava", false, 5);
		add_evaluation_message((portcullises_opened >= 3), "Gate Opener", false, portcullises_opened);
		add_evaluation_message((rooms_lit >= 4), "Light Bringer", false, 2);
		add_evaluation_message((bombs_lit >= 3), "Demolition Expert", false, 2);
		add_evaluation_message((blocks_pushed_into_lava >= 9), "Bridge Maker", false, 2);
		add_evaluation_message(((trapped_chests_opened + trapped_chests_destroyed) >= 3), "Trap Dodger", false, 2);
		add_evaluation_message(((staff_blocked_beams + staff_blocked_fireballs) >= 3), "Projectile Deflector", false, 2);
		add_evaluation_message((illusion_walls_discovered >= 1), "Breaker of Illusions", false, illusion_walls_discovered);
		add_evaluation_message((torches_lit_by_fireball > 0 || bombs_lit_by_fireball > 0), "Improvised Ignition", false, torches_lit_by_fireball+bombs_lit_by_fireball);
		add_evaluation_message((has_won && spontaneously_exploded_enemy > 1), "Survived a Combustion", false, spontaneously_exploded_enemy);
		add_evaluation_message((has_won && mirror_bounced_projectile > 1), "Survived Reflected Shot", false, 1);
		add_evaluation_message((has_won && times_infected > 0), "Survived a Parasite", false, 5);
		add_evaluation_message((global.is_test_mode || (has_won && controller.same_skeleton_type != noone)), "Survived a Special Swarm", false, 10);
		
		// Off and On Bonus/Penalties
		add_evaluation_message((has_won && map_looks == 0), "Mental Mapper", false, 10);
		add_evaluation_message((has_won && crushed_bugs == 0), "Careful Stepper", false, 10);
		add_evaluation_message((crushed_bugs > 10), "Bug Crusher", true, -2);
		add_evaluation_message((has_won && opened_doors == 0), "Entamaphobic", false, 10);
		add_evaluation_message((opened_doors > 20), "Door Slammer", true, -2);
		add_evaluation_message((has_won && rustled_bushes == 0), "Allergic to Nature", false, 10);
		add_evaluation_message((rustled_bushes >= 100), "Invasive Species", true, -2);
		add_evaluation_message((has_won && disturbed_bones == 0), "Respected the Fallen", false, 10);
		add_evaluation_message((disturbed_bones >= 16), "Profaner of the Dead", true, -2);
		add_evaluation_message((has_won && torches_lit == 0), "Adapted to the Dark", false, 10);
		add_evaluation_message((torches_lit >= 16), "Kept the Fire Burning", false, 2);
		add_evaluation_message((dual_wielded_items > 0), "Dual Wielder", false, 1);
		
		// Misc Penalties
		add_evaluation_message((times_infected > 0), "Riddled with Parasites", true, -times_infected);
		add_evaluation_message((chests_opened_lit_bombs >= 1), "Lit Bomb Out of Chest", true, -2*chests_opened_lit_bombs);
		add_evaluation_message((item_lava_count >= 1), "Destroyed Item in Lava", true, -2*item_lava_count);
		add_evaluation_message((decapitated_corpses > 0), "Corpse Desecrator", true, -2*decapitated_corpses);
		//add_evaluation_message((trapped_chests_opened > 0), "Foolish", false, -2);
		
		// Special Room Bonus and Penalties
		add_evaluation_message((giant_eye_room_visited), "Beholder of True Envy", true, -2);
		add_evaluation_message((giant_eye_room_solved), "Eye Blinder", false, 5);
		add_evaluation_message((gudetama_room_visited), "Witnessed True Sloth", true, -2);
		add_evaluation_message((gudetama_room_solved), "Overcame the Roadblock", false, 5);
		add_evaluation_message((hall_of_mirrors_room_visited), "Lost in Your Own Pride", true, -2);
		add_evaluation_message((hall_of_mirrors_room_solved), "Solved the Mirror Maze", false, 5);
		add_evaluation_message((red_chest_room_visited), "Encountered True Greed", true, -2);
		add_evaluation_message((red_chest_room_solved), "Sacrificed an Arm", false, 5);
		add_evaluation_message((special_heart_victory), "Recovered a Pure Heart", false, 10);
		add_evaluation_message((red_chest_room_solved > 1), "Armless Wonder", false, -2);
		add_evaluation_message((inverted_cross_room_visited), "Invoked Wrath Within", true, -2);
		add_evaluation_message((inverted_cross_room_solved), "Retraced Your Steps", false, 5);
		// TODO: Missing Gluttony Room
		// TODO: Missing Lust Room
		
		if (current_score < 0) { current_score = 0; }
		if (current_score > 100) { current_score = 100; }
		var previous_best_score = get_best_score(global.difficulty);
		add_evaluation_message((previous_best_score <= current_score), "New High Score!", false, 0);
		if (!global.is_test_mode) {
			update_best_score(global.difficulty, current_score);
			save_evaluation_variables();
			save_evaluation_messages();
		}
	}

	
	/// @function								add_evaluation_message(criteria, msg, use_special_text, score_modifier);
	/// @param		{bool} criteria				The criteria to pass in order to display this message
	/// @param		{string} msg				The message to display
	/// @param		{bool} use_special_text		Whether to use the special color for this text
	/// @param		{int} score_modifier		The amount that achieving this message modifiers your current score
	function add_evaluation_message(criteria, msg, use_special_text, score_modifier) {
		if (global.is_test_mode || criteria) { 
			array_push(evaluation_messages, [msg, use_special_text]);
			current_score += score_modifier;
		}
	}
	
	/// @function								save_evaluation_variables();
	function save_evaluation_variables() {
		var all_variables = variable_struct_get_names(self);
		
		for(var i = 0; i < array_length(all_variables); i++) {
			var next_variable = all_variables[i];

			switch (next_variable) {
				case "evaluation_messages":
				case "current_score":
				case "bombs_lit_by_fireball":
				case "torches_lit_by_fireball":
				case "clock_time_saved":
				case "map_looks":
				case "map_looks_with_map_item":
				case "spontaneously_exploded_enemy":
				case "dual_wielded_lit_torches":
				case "mirror_bounced_projectile":
				case "chests_opened_lit_bombs":
				case "trapped_chests_opened":
				case "trapped_chests_destroyed":
				case "giant_eye_room_visited":
				case "giant_eye_room_solved":
				case "gudetama_room_visited":
				case "gudetama_room_solved":
				case "hall_of_mirrors_room_visited":
				case "hall_of_mirrors_room_solved":
				case "red_chest_room_visited":
				case "red_chest_room_solved":
				case "special_heart_victory":
				case "inverted_cross_room_visited":
				case "inverted_cross_room_solved":
				case "rustled_bushes":
				case "disturbed_bones":
				case "used_item_types": {
					// Do Nothing
					break;
				}
				case "dual_wielded_items": {
					// Increase it by one
					update_evaluation_variable(next_variable, global.difficulty, 1);
					break;
				}
				default: {
					// Increase it by the variable amount
					var next_value = variable_struct_get(self, next_variable)
					if (is_string(next_value) || is_real(next_value)) { update_evaluation_variable(next_variable, global.difficulty, next_value); }
					break;
				}
			}
		}
	}
	
	function load_evaluation_variables() {
		var all_variables = variable_struct_get_names(self);
		
		for(var i = 0; i < array_length(all_variables); i++) {
			var next_variable = all_variables[i];

			switch (next_variable) {
				case "evaluation_messages":
				case "current_score":
				case "bombs_lit_by_fireball":
				case "torches_lit_by_fireball":
				case "clock_time_saved":
				case "map_looks":
				case "map_looks_with_map_item":
				case "spontaneously_exploded_enemy":
				case "dual_wielded_lit_torches":
				case "mirror_bounced_projectile":
				case "chests_opened_lit_bombs":
				case "trapped_chests_opened":
				case "trapped_chests_destroyed":
				case "giant_eye_room_visited":
				case "giant_eye_room_solved":
				case "gudetama_room_visited":
				case "gudetama_room_solved":
				case "hall_of_mirrors_room_visited":
				case "hall_of_mirrors_room_solved":
				case "red_chest_room_visited":
				case "red_chest_room_solved":
				case "special_heart_victory":
				case "inverted_cross_room_visited":
				case "inverted_cross_room_solved":
				case "rustled_bushes":
				case "disturbed_bones":
				case "used_item_types": {
					// Set to Nothing (unused)
					variable_struct_set(self, next_variable, 0);
					break;
				}
				default: {
					// Set the variable to the saved amount
					variable_struct_set(self, next_variable, get_evaluation_variable(next_variable, global.difficulty));
					break;
				}
			}
		}
	}
	
	/// @function								save_evaluation_messages();
	function save_evaluation_messages() {
		for(var i = 0; i < array_length(evaluation_messages); i++) {
			var next_message = evaluation_messages[i][0];

			if (string_count("Time Elapsed", next_message) ||
				string_count("Collected", next_message) ||
				string_count("Visited Rooms", next_message) ||
				string_count("Escaped Amount", next_message) ||
				string_count("Extra Time Remaining", next_message) ||
				string_count("Death Penalty", next_message) ||
				string_count("Killed Enemies", next_message) ||
				string_count("Cursed Items Used", next_message)) {
					continue;
			}
				
			update_evaluation_variable(next_message, global.difficulty, 1);
		}
	}
	
	/// @function								load_evaluation_messages(sort_mode);
	/// @param		{boolean} sort_by_value		Whether to sort the eval messages by their value
	function load_evaluation_messages(sort_by_value) {
		var prev_test_mode = global.is_test_mode;
		global.is_test_mode = true;
		calculate_evaluation_messages_and_score();
		global.is_test_mode = prev_test_mode;
		
		var loaded_eval_messages = array_create(0);
		for(var i = 0; i < array_length(evaluation_messages); i++) {
			var next_message = evaluation_messages[i];

			if (string_count("Time Elapsed", next_message) ||
				string_count("Collected", next_message) ||
				string_count("Visited Rooms", next_message) ||
				string_count("Escaped Amount", next_message) ||
				string_count("Extra Time Remaining", next_message) ||
				string_count("Death Penalty", next_message) ||
				string_count("Killed Enemies", next_message) ||
				string_count("Cursed Items Used", next_message)) {
					continue;
			}
			array_push(next_message, get_evaluation_variable(next_message[0], global.difficulty));
			array_push(loaded_eval_messages, next_message);
		}
		current_score = 0;
		evaluation_messages = loaded_eval_messages;
		// Sort evaluation messages to display by sort_type
		if (sort_by_value) {
			array_sort(evaluation_messages, function(elm1, elm2) {
				return elm2[2] - elm1[2];
			});
		}
	}
}
