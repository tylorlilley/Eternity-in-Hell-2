/// @description Step
var game_manager = global.game_manager;
var key_space = game_manager.key_space, key_space_pressed = game_manager.key_space_pressed, key_space_released = game_manager.key_space_released;

if (game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	var player = global.player, difficulty = global.difficulty;
	if (player_appear_timer > 0) {
		player_appear_timer -= 1;
		if (player_appear_timer == 0) { player.visible = true; }
	}
	
	if (!is_game_lost() && !is_game_won()) {
		// Play map Sound Effects
		if key_space {
			if key_space_pressed {
				evaluation_manager.increment_evaluation_variable("map_looks");
				var is_using_map = false;
				with (player) { is_using_map = is_carrying_item(obj_map); }
				if (is_using_map) { evaluation_manager.increment_evaluation_variable("map_looks_with_map_item"); }
				if (instance_number(obj_fat_skeleton) == 0) { play_sound(snd_pickup, false); }
			}
			
			with (obj_fat_skeleton) {
				if key_space_pressed { play_sound(snd_fatscream, false); }
					
				var target = get_dropped_meat();
				if (!is_existing_instance(target)) {
					target = player;
				}

				target_x = target.x;
				target_y = target.y;
				set_automatic_target_path();
				move_towards_coordinates_on_path(false, false, 2);
				if (target_path != noone) { play_sound(snd_thud, false); }
				image_index = 2;
				rage_counter = 2;
				turn_to_face_player();
			}
		}
		if key_space_released { play_sound( snd_putdown, false ); }
    
		// Update per frame values
		var time_to_decrement = get_one_unit_of_game_time();
		with (player) {
			if (is_carrying_item_in_right_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_item_in_left_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_special_item(obj_clock)) { time_to_decrement = 0; }
			if (is_carrying_item(obj_clock)) {
				var time_saved = (get_one_unit_of_game_time() - time_to_decrement);
				other.evaluation_manager.increment_evaluation_variable("clock_time_saved", time_saved);
			}
		}
		time_remaining -= time_to_decrement;
		if (is_time_up()) {
			killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
			update_death_log(killed_by, difficulty, false);
			player.dead = true;
			play_sound(snd_lose, false); 
		}
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != directions.none && !blackout) { blackout = true; }
		else if (transition != directions.none && blackout) { 
			var next_room = start_room; 
			if (transition <= directions.stairs) { next_room = transitioning_exit.get_connected_room(current_room); }
			transition_to_room(next_room, true); 
		}
	}
	if (room != rm_finish && (is_game_lost() || is_game_won())) {
		if (is_game_won() || is_time_up() || death_timer == 0) {
			var carried_rosary = noone, carried_dir = directions.none;
			with (player) { 
				carried_rosary = get_carried_item(obj_rosary);
				carried_dir = (right_hand_item == carried_rosary) ? directions.right : directions.left;
				put_down_item(right_hand_item, false, true);
				put_down_item(left_hand_item, false, true);
			}
			if (is_existing_instance(carried_rosary) && player.dead && time_remaining > 0) {
				// Revive and respawn player
				with (player) {
					var player_corpse = instance_create(x, y, obj_player_corpse);
					if (is_existing_instance(player_corpse)) { player_corpse.image_xscale = image_xscale; }
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
				// Destroy or pick up rosary
				if (!carried_rosary.special) { instance_destroy(carried_rosary); } 
				else { with (player) { pick_up_item(carried_rosary, false, carried_dir); } }
			}
			else {
				
				final_time_remaining = time_remaining;
				time_remaining = time_provided;
				evaluation_manager.calculate_evaluation_messages_and_score();
				if (is_game_won()) { update_win_log(difficulty); } // Must be done after calculating score
				with (player) {
					visible = false;
					room_goto(rm_finish);
				}
			}
		}
		else { death_timer -= 1; }
	}
	
	// Update background color
	var new_color = get_game_bg_color();
	if (flash_time > 0) { 
		new_color = merge_color(new_color, c_white, power(flash_time, 2)/power(SCREEN_FLASH_DURATION, 2));
		flash_time -= 1;
		if (flash_time == 0) { flash_obj = noone; }
	}
	global.bg_color = new_color;
	
	if (room == rm_finish) {
		var max_evaluation_pos = array_length(evaluation_manager.evaluation_messages)-6;
	
		if (global.game_manager.key_up_pressed && evaluation_pos > 0) { evaluation_pos -= 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_down_pressed && evaluation_pos < max_evaluation_pos) { evaluation_pos += 1; play_sound(snd_mana, false); }
		else if (global.game_manager.key_up_pressed || global.game_manager.key_down_pressed) { play_sound(snd_locked, false); }
	}
}



// DEBUG MODE SPAWNER
if (global.is_test_mode) {
	if (mouse_check_button_pressed(mb_left)) {
		var obj_type = obj_compass;
		var new_instance = instance_create(mouse_x, mouse_y, obj_type);
		with (new_instance) { move_snap(8, 8); make_item_special(); }
	}
	if (mouse_check_button_pressed(mb_right)) {
		var obj_type = obj_cultist;
		var new_instance = instance_create(mouse_x, mouse_y, obj_type);
		with (new_instance) { move_snap(8, 8); }
	}
}
