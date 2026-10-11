/// @description Step
var _game_manager = global.game_manager;
var _key_space = _game_manager.key_space, _key_space_pressed = _game_manager.key_space_pressed, _key_space_released = _game_manager.key_space_released;

if (_game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	var _player = global.player;
	if (player_appear_timer > 0) {
		player_appear_timer -= 1;
		if (player_appear_timer == 0) { _player.visible = true; }
	}
	
	if (!is_game_lost() && !is_game_won()) {
		// Play map Sound Effects
		if _key_space {
			if _key_space_pressed {
				var _is_using_map = false;
				with (_player) { _is_using_map = is_carrying_item(obj_map); }
				run_record.record_map_look(current_room, _is_using_map);
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
    
		// Update per frame values
		var _time_to_decrement = get_one_unit_of_game_time();
		with (_player) {
			if (is_carrying_item_in_right_hand(obj_clock)) { _time_to_decrement/= 2; }
			if (is_carrying_item_in_left_hand(obj_clock)) { _time_to_decrement/= 2; }
			if (is_carrying_special_item(obj_clock)) { _time_to_decrement = 0; }
			if (is_carrying_item(obj_clock)) {
				var _time_saved = (get_one_unit_of_game_time() - _time_to_decrement);
				increment_run_stat("clock_time_saved", _time_saved);
			}
		}
		time_remaining -= _time_to_decrement;
		if (is_time_up()) {
			killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
			record_run_death(killed_by);
			_player.dead = true;
			play_sound(snd_lose, false); 
		}
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != directions.none && !blackout) { blackout = true; }
		else if (transition != directions.none && blackout) { 
			var _next_room = start_room; 
			if (transition <= directions.stairs) { _next_room = transitioning_exit.get_connected_room(current_room); }
			transition_to_room(_next_room, true); 
		}
	}
	if (room != rm_finish && (is_game_lost() || is_game_won())) {
		if (is_game_won() || is_time_up() || death_timer == 0) {
			var _carried_rosary = noone, _carried_dir = directions.none;
			with (_player) { 
				_carried_rosary = get_carried_item(obj_rosary);
				_carried_dir = (right_hand_item == _carried_rosary) ? directions.right : directions.left;
				put_down_item(right_hand_item, false, true);
				put_down_item(left_hand_item, false, true);
			}
			if (is_existing_instance(_carried_rosary) && _player.dead && time_remaining > 0) {
				// Revive and respawn player
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
				increment_run_stat("rosary_use_count");
				transition = directions.respawn;
				// Destroy or pick up rosary
				if (!_carried_rosary.special) { instance_destroy(_carried_rosary); } 
				else { with (_player) { pick_up_item(_carried_rosary, false, _carried_dir); } }
			}
			else {
				
				final_time_remaining = time_remaining;
				time_remaining = time_provided;
				run_record.evaluate();
				run_record.save();
				with (_player) {
					visible = false;
					room_goto(rm_finish);
				}
			}
		}
		else { death_timer -= 1; }
	}
	
	// Update background color
	var _new_color = get_game_bg_color();
	if (flash_time > 0) { 
		_new_color = merge_color(_new_color, c_white, power(flash_time, 2)/power(SCREEN_FLASH_DURATION, 2));
		flash_time -= 1;
		if (flash_time == 0) { flash_obj = noone; }
	}
	global.bg_color = _new_color;
	
	if (room == rm_finish) {
		var _max_evaluation_pos = array_length(run_record.evaluation_messages)-6;
	
		if (global.game_manager.key_up_pressed && evaluation_pos > 0) { evaluation_pos -= 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_down_pressed && evaluation_pos < _max_evaluation_pos) { evaluation_pos += 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_up_pressed || global.game_manager.key_down_pressed) { play_sound(snd_locked, false); }
	}
}



// DEBUG MODE SPAWNER
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
