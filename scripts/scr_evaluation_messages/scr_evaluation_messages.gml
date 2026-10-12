/// @function create_run_stats()
/// @description Every stat a run counts, each starting at 0. This and get_evaluation_messages below are the one
///	place stats and evaluation messages are defined. Code anywhere in the game adds to a stat by name with
///	increment_run_stat, the evaluation messages judge the run on the stats when it ends, and each save file keeps
///	their totals over every run it holds (see scr_player_data). To add a stat, add it here and call
///	increment_run_stat where it happens.
/// @returns {struct} Each stat's name, set to 0
function create_run_stats() {
	return {
		// Deaths
		death_count: 0,									// Times the player died, including deaths a rosary undid, running out of time and restarting from the pause menu
		rosary_use_count: 0,							// Times a rosary brought the player back to life

		// Kills (see record_run_kill for which kills are recorded)
		kill_count: 0,									// Enemies killed by anything but another enemy's projectile
		kill_after_death_count: 0,						// Enemies killed while the player was dead
		sword_kill_count: 0,							// Enemies the player killed with a sword
		block_kill_count: 0,							// Enemies crushed under a block the player pushed
		double_block_kill_count: 0,						// Pushes that crushed two or more enemies under one block
		nose_block_kill_count: 0,						// Noses crushed under a block the player pushed
		worm_kill_count: 0,								// Enemies crushed under the giant worm
		lava_kill_count: 0,								// Enemies killed by lava
		meat_kill_count: 0,								// Enemies killed by eating special meat
		bomb_kill_count: 0,								// Enemies killed by the blast of a bomb the player set off
		friendly_fire_kill_count: 0,					// Enemies killed by another enemy's projectile
		spontaneously_exploded_enemy: 0,				// Noses and fire skeletons that blew themselves up

		// Items
		used_item_types: 0,								// Types of item the player picked up
		used_special_items: 0,							// Special items the player carried into another room
		dual_wielded_items: 0,							// Times the player came to hold two items of the same type
		dual_wielded_lit_torches: 0,					// Times the player came to hold two lit torches
		staff_blocked_fireballs: 0,						// Fireballs a carried staff blocked
		staff_blocked_beams: 0,							// Magic beams a carried staff blocked
		holes_dug: 0,									// Holes dug with a shovel
		bombs_lit: 0,									// Bombs the player lit
		bombs_lit_by_fireball: 0,						// Bombs a fireball lit while the player was alive
		torches_lit: 0,									// Torches lit, counting the one the player may begin with
		torches_lit_by_fireball: 0,						// Torches a fireball lit while the player was alive
		special_torches_lit: 0,							// Special torches lit
		carried_torch_lost_count: 0,					// Times the player put down their last torch, dropped it by dying, or let a carried torch go out
		rooms_lit: 0,									// Rooms where the player lit the last unlit lantern
		clock_time_saved: 0,							// Seconds a carried clock kept from running out
		item_lava_count: 0,								// Items destroyed by lava
		decapitated_corpses: 0,							// Heads the player ripped off of corpses
		total_collectables_collected: 0,				// Collectables picked up

		// Map
		map_looks: 0,									// Times the player opened the map
		rooms_map_looked_at_with_map_item: 0,			// Rooms the player opened the map in while carrying a map
		rooms_map_looked_at_without_map_item: 0,		// Rooms the player opened the map in without carrying a map

		// Chests
		chests_opened: 0,								// Chests opened, other than trapped ones
		chests_opened_lit_bombs: 0,						// Bombs a chest dropped at the player's feet while they carried a lit torch
		trapped_chests_opened: 0,						// Trapped chests opened
		trapped_chests_destroyed: 0,					// Trapped chests destroyed by the blast of a bomb the player set off
		unlocked_chests: 0,								// Locked chests unlocked

		// Doors and exits
		opened_doors: 0,								// Doors opened
		unlocked_doors: 0,								// Locked doors unlocked
		portcullises_opened: 0,							// Portcullises opened by stepping on a plate
		illusion_walls_discovered: 0,					// Illusion walls the player walked through

		// Tiles and hazards
		crushed_bugs: 0,								// Bugs the player stepped on
		times_infected: 0,								// Times a parasite infected the player
		rustled_bushes: 0,								// Times the player rustled a bush
		disturbed_bones: 0,								// Corpses and bones the player stepped on
		blocks_pushed_into_lava: 0,						// Blocks pushed into lava
		mirror_bounced_projectile: 0,					// Times a projectile bounced off of a mirror

		// Special rooms
		giant_eye_room_visited: 0,						// Envy rooms found
		giant_eye_room_solved: 0,						// Envy rooms solved, by destroying the giant eye
		gudetama_room_visited: 0,						// Sloth rooms found
		gudetama_room_solved: 0,						// Sloth rooms solved, by killing the gudetama
		hall_of_mirrors_room_visited: 0,				// Pride rooms found
		hall_of_mirrors_room_solved: 0,					// Pride rooms solved, by finding the way through the hall of mirrors
		red_chest_room_visited: 0,						// Greed rooms found
		red_chest_room_solved: 0,						// Arms the red chest took, with the item they held
		inverted_cross_room_visited: 0,					// Wrath rooms found
		inverted_cross_room_solved: 0,					// Wrath rooms solved, by going back to the cross
		special_heart_victory: 0						// Wins carrying a purified heart
	};
}

/// @function get_evaluation_messages()
/// @description Every message the end-of-run evaluation can show, in the order it shows them. To add a message, add
///	a line to EvaluationMessageList below.
/// @returns {array} The EvaluationMessage structs
function get_evaluation_messages() {
	static message_list = new EvaluationMessageList();
	return message_list.messages;
}

/// @function EvaluationMessage(_title, _description, _is_negative, _score_value, _is_earned, [_get_text])
/// @description One message the end-of-run evaluation can show, and what it adds to the run's score. An achievement
///	shows its title, and the save files count how many runs earned it. A score line (one given _get_text) shows a
///	measure of the run instead, like the share of rooms visited, and isn't counted. Its functions run as methods of
///	the RunRecord being judged (see RunRecord.evaluate), so they read the run directly: its stats as stats.name (see
///	create_run_stats), and what evaluate measures when the run ends, like has_won.
/// @param {string} _title The name shown, and the name the save files count it under
/// @param {string} _description What earns it, for the title screen
/// @param {bool} _is_negative Whether it's drawn in the game color, as a penalty or bad news
/// @param {real|function} _score_value What it adds to the score, or a function that works that out
/// @param {function} _is_earned A function that says whether the run earned it
/// @param {function} [_get_text] For a score line, a function that returns the text to show
function EvaluationMessage(_title, _description, _is_negative, _score_value, _is_earned, _get_text = undefined) constructor {
	title = _title;
	description = _description;
	is_negative = _is_negative;
	score_value = _score_value;
	is_earned = _is_earned;
	get_text = _get_text;
	is_achievement = is_undefined(_get_text);
}

/// @function EvaluationMessageList()
/// @description The table of every evaluation message, built once by get_evaluation_messages. Each message is one
///	entry: its title, its description, whether it's negative, its score and the test that earns it. The functions are
///	written as if inside the RunRecord being judged, which runs each one as its own method (see EvaluationMessage).
function EvaluationMessageList() constructor {
	messages = [];

	/// @function add_message(_title, _description, _is_negative, _score_value, _is_earned)
	/// @description Adds an achievement, shown by its title and counted in the save files (see EvaluationMessage)
	/// @param {string} _title The name shown and counted
	/// @param {string} _description What earns it, for the title screen
	/// @param {bool} _is_negative Whether it's drawn in the game color
	/// @param {real|function} _score_value What it adds to the score, or a function that works that out
	/// @param {function} _is_earned A function that says whether the run earned it
	static add_message = function(_title, _description, _is_negative, _score_value, _is_earned) {
		array_push(messages, new EvaluationMessage(_title, _description, _is_negative, _score_value, _is_earned));
	};

	/// @function add_score_line(_title, _is_negative, _score_value, _is_earned, _get_text)
	/// @description Adds a score line, which shows a measure of the run and isn't counted (see EvaluationMessage)
	/// @param {string} _title A name for the line
	/// @param {bool} _is_negative Whether it's drawn in the game color
	/// @param {real|function} _score_value What it adds to the score, or a function that works that out
	/// @param {function} _is_earned A function that says whether the run shows it
	/// @param {function} _get_text A function that returns the text to show
	static add_score_line = function(_title, _is_negative, _score_value, _is_earned, _get_text) {
		array_push(messages, new EvaluationMessage(_title, "", _is_negative, _score_value, _is_earned, _get_text));
	};

	// The run's main measures
	add_score_line("Time Elapsed", false, 0,
		function() { return true; },
		function() { return "Time Elapsed: " + get_percentage_string(time_elapsed_percent); });
	add_score_line("Collected", false, function() { return collected_percent / 3; },
		function() { return true; },
		function() { return "Collected: " + get_percentage_string(collected_percent); });
	add_score_line("Visited Rooms", false, function() { return visited_rooms_percent / 3; },
		function() { return true; },
		function() { return "Visited Rooms: " + get_percentage_string(visited_rooms_percent); });
	add_score_line("Escaped Amount", false, function() { return escaped_percent / 10; },
		function() { return completion_amount > 0; },
		function() { return "Escaped Amount: " + get_percentage_string(escaped_percent); });
	add_score_line("Extra Time Remaining", false, function() { return time_remaining_percent / 10; },
		function() { return has_won; },
		function() { return "Extra Time Remaining: " + get_percentage_string(time_remaining_percent); });
	add_score_line("Death Penalty", true, function() { return stats.rosary_use_count * -5; },
		function() { return stats.rosary_use_count > 0; },
		function() { return "Death Penalty: " + string(stats.rosary_use_count); });
	add_message("Novel Death", "Died to something that had never killed you before.", true, 0,
		function() { return has_novel_death(); });
	add_score_line("Killed Enemies", false, function() { return stats.kill_count; },
		function() { return stats.kill_count > 0; },
		function() { return "Killed Enemies: " + string(stats.kill_count); });
	add_score_line("Cursed Items Used", true, function() { return stats.used_special_items * -10; },
		function() { return stats.used_special_items > 0; },
		function() { return "Cursed Items Used: " + string(stats.used_special_items); });

	// Items
	add_message("Resourceful", "Picked up 4 or more types of items, and one more for each item you began with.", false, function() { return used_item_score; },
		function() { return used_item_score > 0; });
	add_message("Courageous Preparation", "Won after beginning with both hands empty.", false, 10,
		function() { return has_won && starting_left_hand_item == noone && starting_right_hand_item == noone; });
	add_message("Overprepared", "Began with both hands full.", true, -5,
		function() { return starting_left_hand_item != noone && starting_right_hand_item != noone; });
	add_message("Returned Empty-Handed", "Won with one empty hand.", true, -5,
		function() { return has_won && (final_left_hand_item == noone || final_right_hand_item == noone); });
	add_message("Returned with a Memento", "Won while carrying an item you didn't begin with.", false, 5,
		function() { return has_won && (is_found_item(final_right_hand_item) || is_found_item(final_left_hand_item)); });
	add_message("New Item Recovered", "Won while carrying an item you had never won with before.", false, 0,
		function() { return has_won && (is_first_win_with_item(final_left_hand_item) || is_first_win_with_item(final_right_hand_item)); });

	// Item mastery
	add_message("Sword Master", "Defeated 3 or more enemies with a sword.", false, 5,
		function() { return stats.sword_kill_count >= 3; });
	add_message("Devoted Follower", "Was resurrected 3 or more times.", false, 5,
		function() { return stats.rosary_use_count >= 3; });
	add_message("Master Lockpicker", "Unlocked a total of 5 or more locked chests and doors.", false, 5,
		function() { return (stats.unlocked_doors + stats.unlocked_chests) >= 5; });
	add_message("Tunnel Digger", "Dug 6 or more holes with a shovel.", false, 5,
		function() { return stats.holes_dug >= 6; });
	add_message("Expert Poisoner", "Used cursed bait to defeat 3 or more enemies.", false, 5,
		function() { return stats.meat_kill_count >= 3; });
	add_message("Time Saver", "Saved over a minute of time while using a clock.", false, 5,
		function() { return stats.clock_time_saved > 60; });
	add_message("Shone Brightly", "Carried one or more items that increase your light range beyond that of a single torch.", false, 5,
		function() { return stats.special_torches_lit > 0 || stats.dual_wielded_lit_torches > 0; });
	add_message("Consulter of Maps", "Looked at a carried map in more than half of the rooms.", false, 5,
		function() { return stats.rooms_map_looked_at_with_map_item > map_room_count / 2 && stats.rooms_map_looked_at_without_map_item <= map_room_count / 2; });
	add_message("Map Overreliance", "Looked at your map without carrying one in more than half of the rooms.", true, -2,
		function() { return stats.rooms_map_looked_at_without_map_item > map_room_count / 2; });

	// Feats
	add_message("Treasure Hunter", "Opened 5 or more chests.", false, 2,
		function() { return stats.chests_opened >= 5; });
	add_message("Monster Slayer", "Defeated 10 or more enemies.", false, 2,
		function() { return stats.kill_count >= 10; });
	add_message("Posthumous Revenge", "Defeated an enemy while you were dead.", false, 2,
		function() { return stats.kill_after_death_count >= 1; });
	add_message("Friendly Fire", "Defeated an enemy with another enemy's projectile.", false, 2,
		function() { return stats.friendly_fire_kill_count > 0; });
	add_message("Accidental Kill", "Defeated an enemy by crushing it under another enemy.", false, 2,
		function() { return stats.worm_kill_count > 0; });
	add_message("Bulldozer", "Defeated 4 or more enemies by crushing them under blocks.", false, 2,
		function() { return stats.block_kill_count >= 4; });
	add_message("Two Birds One Block", "Defeated 2 or more enemies by crushing them under a single block at the same time.", false, 5,
		function() { return stats.double_block_kill_count >= 1; });
	add_message("Bulldozed in Lava", "Defeated an enemy by crushing them under a block while it was in lava.", false, 5,
		function() { return stats.nose_block_kill_count >= 1; });
	add_message("Gate Opener", "Stepped on plates to open 3 or more portcullises.", false, function() { return stats.portcullises_opened; },
		function() { return stats.portcullises_opened >= 3; });
	add_message("Light Bringer", "Fully lit up 4 or more rooms.", false, 2,
		function() { return stats.rooms_lit >= 4; });
	add_message("Demolition Expert", "Exploded 3 or more bombs.", false, 2,
		function() { return stats.bombs_lit >= 3; });
	add_message("Bridge Maker", "Pushed 9 or more blocks into lava.", false, 2,
		function() { return stats.blocks_pushed_into_lava >= 9; });
	add_message("Trap Dodger", "Opened or destroyed 3 or more trapped chests.", false, 2,
		function() { return (stats.trapped_chests_opened + stats.trapped_chests_destroyed) >= 3; });
	add_message("Projectile Deflector", "Blocked 3 or more projectiles with a staff.", false, 2,
		function() { return (stats.staff_blocked_beams + stats.staff_blocked_fireballs) >= 3; });
	add_message("Breaker of Illusions", "Exited a room through an illusion wall.", false, function() { return stats.illusion_walls_discovered; },
		function() { return stats.illusion_walls_discovered >= 1; });
	add_message("Improvised Ignition", "Lit a torch or bomb via an enemy's projectile.", false, function() { return stats.torches_lit_by_fireball + stats.bombs_lit_by_fireball; },
		function() { return stats.torches_lit_by_fireball > 0 || stats.bombs_lit_by_fireball > 0; });
	add_message("Survived a Combustion", "Won after witnessing an enemy's spontaneous combustion.", false, function() { return stats.spontaneously_exploded_enemy; },
		function() { return has_won && stats.spontaneously_exploded_enemy >= 1; });
	add_message("Survived Reflected Shot", "Won after witnessing an enemy's projectile bounce off of a mirror.", false, 1,
		function() { return has_won && stats.mirror_bounced_projectile >= 1; });
	add_message("Survived a Parasite", "Won after becoming infected by a parasite.", false, 5,
		function() { return has_won && stats.times_infected > 0; });
	add_message("Survived a Special Swarm", "Won despite all standard enemies being replaced by the same enemy type.", false, 10,
		function() { return has_won && had_special_swarm; });

	// Restraint, and its opposite
	add_message("Mental Mapper", "Won without ever looking at the map.", false, 10,
		function() { return has_won && stats.map_looks == 0; });
	add_message("Careful Stepper", "Won without stepping on any bugs.", false, 10,
		function() { return has_won && stats.crushed_bugs == 0; });
	add_message("Bug Crusher", "Stepped on more than 10 bugs.", true, -2,
		function() { return stats.crushed_bugs > 10; });
	add_message("Entamaphobic", "Won without opening any doors.", false, 10,
		function() { return has_won && stats.opened_doors == 0; });
	add_message("Door Slammer", "Opened more than 20 doors.", true, -2,
		function() { return stats.opened_doors > 20; });
	add_message("Allergic to Nature", "Won without ever touching any bushes.", false, 10,
		function() { return has_won && stats.rustled_bushes == 0; });
	add_message("Invasive Species", "Rustled a bush 100 or more times.", true, -2,
		function() { return stats.rustled_bushes >= 100; });
	add_message("Respected the Fallen", "Won without ever touching any corpses or bones.", false, 10,
		function() { return has_won && stats.disturbed_bones == 0; });
	add_message("Profaner of the Dead", "Stepped on a total of 16 or more corpses or bones.", true, -2,
		function() { return stats.disturbed_bones >= 16; });
	add_message("Adapted to the Dark", "Won without lighting any torches.", false, 10,
		function() { return has_won && stats.torches_lit == 0; });
	add_message("Kept the Fire Burning", "Won after beginning with a lit torch and never putting it down or letting it go out.", false, 5,
		function() { return has_won && began_with_item(obj_torch) && is_holding_item_at_end(obj_torch) && stats.carried_torch_lost_count == 0; });
	add_message("Master Collector", "Collected 100 or more in a single run.", false, 2,
		function() { return stats.total_collectables_collected >= 100; });
	add_message("Dual Wielder", "Carried two of the same item type at once.", false, 1,
		function() { return stats.dual_wielded_items > 0; });

	// Penalties
	add_message("Riddled with Parasites", "Became infected by a parasite at least once.", true, function() { return -stats.times_infected; },
		function() { return stats.times_infected > 0; });
	add_message("Lit Bomb Out of Chest", "Opened a chest containing a bomb while carrying at least one lit torch and another item.", true, function() { return stats.chests_opened_lit_bombs * -2; },
		function() { return stats.chests_opened_lit_bombs >= 1; });
	add_message("Destroyed Item in Lava", "Dropped an item into lava.", true, function() { return stats.item_lava_count * -2; },
		function() { return stats.item_lava_count >= 1; });
	add_message("Corpse Desecrator", "Ripped the head off of a corpse.", true, function() { return stats.decapitated_corpses * -2; },
		function() { return stats.decapitated_corpses > 0; });

	// Special rooms
	add_message("Beholder of True Envy", "Found the special envy puzzle room.", true, -2,
		function() { return stats.giant_eye_room_visited > 0; });
	add_message("Eye Blinder", "Found and solved the special envy puzzle room.", false, 5,
		function() { return stats.giant_eye_room_solved > 0; });
	add_message("Witnessed True Sloth", "Found the special sloth puzzle room.", true, -2,
		function() { return stats.gudetama_room_visited > 0; });
	add_message("Overcame the Roadblock", "Found and solved the special sloth puzzle room.", false, 5,
		function() { return stats.gudetama_room_solved > 0; });
	add_message("Lost in Your Own Pride", "Found the special pride puzzle room.", true, -2,
		function() { return stats.hall_of_mirrors_room_visited > 0; });
	add_message("Solved the Mirror Maze", "Found and solved the special pride puzzle room.", false, 5,
		function() { return stats.hall_of_mirrors_room_solved > 0; });
	add_message("Encountered True Greed", "Found the special greed puzzle room.", true, -2,
		function() { return stats.red_chest_room_visited > 0; });
	add_message("Sacrificed an Arm", "Found and solved the special greed puzzle room.", false, 5,
		function() { return stats.red_chest_room_solved > 0; });
	add_message("Recovered a Pure Heart", "Won while carrying a purified heart.", false, 10,
		function() { return stats.special_heart_victory > 0; });
	add_message("Armless Wonder", "Gave both of your arms to the special greed puzzle room.", true, -2,
		function() { return stats.red_chest_room_solved > 1; });
	add_message("Invoked Wrath Within", "Found the special wrath puzzle room.", true, -2,
		function() { return stats.inverted_cross_room_visited > 0; });
	add_message("Retraced Your Steps", "Found and solved the special wrath puzzle room.", false, 5,
		function() { return stats.inverted_cross_room_solved > 0; });
	// TODO: Add messages for the gluttony and lust rooms

	// Keep this last: it compares the score every message above adds up to, clamped as RunRecord.evaluate clamps it
	add_message("New High Score!", "Beat your best grade on this difficulty.", false, 0,
		function() { return clamp(run_score, 0, 100) > previous_totals.best_score; });
}
