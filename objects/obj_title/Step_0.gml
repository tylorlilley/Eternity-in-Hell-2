if (pos == -2) { pos = (global.can_access_farmer_mode) ? -1 : 0; }

if (blink_timer == 0) {
	blink = !blink;
	blink_timer = 15;
}
else { blink_timer -= 1; }

if (keyboard_check_pressed(vk_space)) { play_sound(snd_pickup, false); }
if (keyboard_check_released(vk_space)) { play_sound(snd_pickup, false); }

if keyboard_check(vk_space) {
	// do nothing
}
else {
	// Adjust selected setting
	if (keyboard_check_pressed(vk_up) && (pos > 0 || (pos > -1 && global.can_access_farmer_mode))) { pos -= 1; play_sound(snd_mana, false); }
	else if (keyboard_check_pressed(vk_down) && pos < 2) { pos += 1; play_sound(snd_mana, false); }
	
	// Adjust Farmer Mode Settings
	var prev_difficulty = global.difficulty;
	if (pos == -1) {
		if (global.FARM_MODE && keyboard_check_pressed(vk_left)) { global.FARM_MODE = false; play_sound(snd_putdown, false); }
		else if (!global.FARM_MODE && keyboard_check_pressed(vk_right)) { global.FARM_MODE = true; play_sound(snd_pickup, false); }
	}

	// Adjust Difficulty Settings
	var prev_difficulty = global.difficulty;
	if (pos == 0) {
		if (global.difficulty > difficulties.easy && keyboard_check_pressed(vk_left)) { global.difficulty -= 1; }
		else if (global.difficulty < difficulties.very_hard && keyboard_check_pressed(vk_right)) { global.difficulty += 1; }
		if (prev_difficulty != global.difficulty) {
			var difficulty_sound = noone;
			switch (global.difficulty) {
				case difficulties.easy: { difficulty_sound = snd_pickup; break; }
				case difficulties.medium: { difficulty_sound = snd_putdown; break; }
				case difficulties.hard: { difficulty_sound = snd_skeletonrise; break; }
				case difficulties.very_hard: { difficulty_sound = snd_lose; break; }
			}
			if (difficulty_sound) { play_sound(difficulty_sound, false); }
		}
	}

	// Adjust Seed Option Settings
	else if (pos == 1) {
		if ((global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) && keyboard_check_pressed(vk_left)) { global.seed_option -= 1; play_sound(snd_mana, false); }
		else if (global.seed_option < seed_options.specified && keyboard_check_pressed(vk_right)) { global.seed_option += 1; play_sound(snd_mana, false); }
	}

	// Adjust Seed Manually
	if (current_seed == noone) { current_seed = global.seed ? global.seed : irandom_range(0,99999999); }
	else if (pos == 2) {
		if (keyboard_check_pressed(vk_backspace)) { 
			if (current_seed > 0) {
				current_seed = floor(current_seed / 10); 
				play_sound(snd_move, false);
			}
			else { play_sound(snd_crunch, false); }
		}
		else if (current_seed > 0 && keyboard_check_pressed(vk_left)) { current_seed -= 1; play_sound(snd_move, false); }
		else if (current_seed < 99999999 && keyboard_check_pressed(vk_right)) { current_seed += 1; play_sound(snd_move, false); }
		else {
			var new_number = noone;
			if (keyboard_check_pressed(ord("1"))) { new_number = 1; }
			else if (keyboard_check_pressed(ord("2"))) { new_number = 2; }
			else if (keyboard_check_pressed(ord("3"))) { new_number = 3; }
			else if (keyboard_check_pressed(ord("4"))) { new_number = 4; }
			else if (keyboard_check_pressed(ord("5"))) { new_number = 5; }
			else if (keyboard_check_pressed(ord("6"))) { new_number = 6; }
			else if (keyboard_check_pressed(ord("7"))) { new_number = 7; }
			else if (keyboard_check_pressed(ord("8"))) { new_number = 8; }
			else if (keyboard_check_pressed(ord("9"))) { new_number = 9; }
			else if (keyboard_check_pressed(ord("0"))) { new_number = 0; }
			if (new_number != noone) {
				if (current_seed < 99999999) {
					current_seed = (current_seed * 10) + new_number;
					play_sound(snd_move, false);
				}
				else { play_sound(snd_crunch, false); }
			}
		}
	}
	
	// Start Game
	if (keyboard_check_released(vk_enter)) {
		play_sound(snd_move, false);
		if (global.seed_option == seed_options.specified) { global.seed = current_seed; }
		else if (global.seed_option == seed_options.rand) { global.seed = irandom_range(0,99999999); }
		room_goto(rm_start);
	}
}
