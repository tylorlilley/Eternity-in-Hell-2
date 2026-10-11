/// @description Step
var _game_manager = global.game_manager;
var _key_space = _game_manager.key_space, _key_space_pressed = _game_manager.key_space_pressed, _key_space_released = _game_manager.key_space_released;

// The game updates only once every FRAMES_TO_WAIT_BEFORE_PROCESSING frames, and acts on the player's input then
if (_game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	var _player = global.player, _difficulty = global.difficulty;
	// Show the player again once the delay after taking stairs or respawning runs out
	if (player_appear_timer > 0) {
		player_appear_timer -= 1;
		if (player_appear_timer == 0) { _player.visible = true; }
	}
	
	if (!is_game_lost() && !is_game_won()) {
		// While the player looks at the map, count the looks for the evaluation and play the map's sounds. Fat
		// skeletons scream instead, and charge at the player while they look, unless there's dropped meat to go for.
		if _key_space {
			if _key_space_pressed {
				evaluation_manager.increment_evaluation_variable("map_looks");
				var _is_using_map = false;
				with (_player) { _is_using_map = is_carrying_item(obj_map); }
				if (_is_using_map) { evaluation_manager.increment_evaluation_variable("map_looks_with_map_item"); }
				if (instance_number(obj_fat_skeleton) == 0) { play_sound(snd_pickup, false); }
			}
			with (obj_fat_skeleton) {
				var _target = get_dropped_meat();
				if (!is_existing_instance(_target)) {
					if _key_space_pressed { play_sound(snd_fatscream, false); }
					_target = _player;
					target_x = _target.x;
					target_y = _target.y;
					set_automatic_target_path();
					move_towards_coordinates_on_path(false, false, 2);
					if (target_path != noone) { play_sound(snd_thud, false); }
					image_index = 2;
					rage_counter = 2;
					turn_to_face_player();
				}
			}
		}
		if _key_space_released { play_sound( snd_putdown, false ); }
    
		// Count down the time. Each clock held halves the time taken and a special clock stops it, and the evaluation
		// counts the time saved.
		var _time_to_decrement = get_one_unit_of_game_time();
		with (_player) {
			if (is_carrying_item_in_right_hand(obj_clock)) { _time_to_decrement/= 2; }
			if (is_carrying_item_in_left_hand(obj_clock)) { _time_to_decrement/= 2; }
			if (is_carrying_special_item(obj_clock)) { _time_to_decrement = 0; }
			if (is_carrying_item(obj_clock)) {
				var _time_saved = (get_one_unit_of_game_time() - _time_to_decrement);
				other.evaluation_manager.increment_evaluation_variable("clock_time_saved", _time_saved);
			}
		}
		time_remaining -= _time_to_decrement;
		// Once time is up the player dies, killed by the clock (obj_controller), or by the mirror in a hall of mirrors
		if (is_time_up()) {
			killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
			update_death_log(killed_by, _difficulty, false);
			_player.dead = true;
			play_sound(snd_lose, false); 
		}
		
		// Room transitions take two updates, to get around a macOS drawing bug: the first blacks out the screen and the
		// second changes rooms. A respawn goes to the start room, and other transitions go through their exit.
		if (transition != directions.none && !blackout) { blackout = true; }
		else if (transition != directions.none && blackout) { 
			var _next_room = start_room; 
			if (transition <= directions.stairs) { _next_room = transitioning_exit.get_connected_room(current_room); }
			transition_to_room(_next_room, true); 
		}
	}
	// End of the game: the player puts down their items, then a carried rosary may revive them, or else the game is
	// scored and goes to the finish screen
	if (room != rm_finish && (is_game_lost() || is_game_won())) {
		// Right away for a win or once time is up, and once death_timer runs out for any other death
		if (is_game_won() || is_time_up() || death_timer == 0) {
			var _carried_rosary = noone, _carried_dir = directions.none;
			with (_player) { 
				_carried_rosary = get_carried_item(obj_rosary);
				_carried_dir = (right_hand_item == _carried_rosary) ? directions.right : directions.left;
				put_down_item(right_hand_item, false, true);
				put_down_item(left_hand_item, false, true);
			}
			if (is_existing_instance(_carried_rosary) && _player.dead && time_remaining > 0) {
				// A rosary revives a player who died with time left: they leave a corpse and respawn in the start room
				with (_player) {
					var _player_corpse = instance_create(x, y, obj_player_corpse);
					if (is_existing_instance(_player_corpse)) { _player_corpse.image_xscale = image_xscale; }
					x = -8;
					y = -8;
					dead = false;
					image_index = 0;
					depth = PLAYER_DEPTH;
					visible = false;
					player_appear_timer = 2;
				}
				evaluation_manager.increment_evaluation_variable("rosary_use_count");
				transition = directions.respawn;
				// A plain rosary is used up, and a special one goes back into the hand it was in
				if (!_carried_rosary.special) { instance_destroy(_carried_rosary); } 
				else { with (_player) { pick_up_item(_carried_rosary, false, _carried_dir); } }
			}
			else {
				
				// Otherwise the game is over: score it and go to the finish screen
				final_time_remaining = time_remaining;
				time_remaining = time_provided;
				evaluation_manager.calculate_evaluation_messages_and_score();
				if (is_game_won()) { update_win_log(_difficulty); } // Must be done after calculating score
				with (_player) {
					visible = false;
					room_goto(rm_finish);
				}
			}
		}
		else { death_timer -= 1; }
	}
	
	// Update the background color, fading a screen flash out from white
	var _new_color = get_game_bg_color();
	if (flash_time > 0) { 
		_new_color = merge_color(_new_color, c_white, power(flash_time, 2)/power(SCREEN_FLASH_DURATION, 2));
		flash_time -= 1;
		if (flash_time == 0) { flash_obj = noone; }
	}
	global.bg_color = _new_color;
	
	// On the finish screen, up and down scroll the evaluation messages, with the locked sound at either end
	if (room == rm_finish) {
		var _max_evaluation_pos = array_length(evaluation_manager.evaluation_messages)-6;
	
		if (global.game_manager.key_up_pressed && evaluation_pos > 0) { evaluation_pos -= 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_down_pressed && evaluation_pos < _max_evaluation_pos) { evaluation_pos += 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_up_pressed || global.game_manager.key_down_pressed) { play_sound(snd_locked, false); }
	}
}



// Test mode spawner: a left click spawns a mirror at the mouse, and a right click a cockroach
if (global.is_test_mode) {
	if (mouse_check_button_pressed(mb_left)) {
		var _obj_type = obj_mirror;
		var _new_instance = instance_create(mouse_x, mouse_y, _obj_type);
		with (_new_instance) { move_snap(8, 8); contents_obj = obj_torch; }
	}
	if (mouse_check_button_pressed(mb_right)) {
		var _obj_type = obj_cockroach;
		var _new_instance = instance_create(mouse_x, mouse_y, _obj_type);
		with (_new_instance) { move_snap(8, 8); infectious = true; }
	}
}
