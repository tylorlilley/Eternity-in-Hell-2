/// @description Step
var game_manager = global.game_manager;
var key_space_pressed = game_manager.key_space_pressed, key_space_released = game_manager.key_space_released;

if (game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	var player = global.player, difficulty = global.difficulty;
	if (player_appear_timer > 0) {
		player_appear_timer -= 1;
		if (player_appear_timer == 0) { player.visible = true; }
	}
	
	if (!is_game_lost() && !is_game_won()) {
		// Play map Sound Effects
		if key_space_pressed { play_sound( snd_pickup, false ); }
		if key_space_released { play_sound( snd_putdown, false ); }
    
		// Update per frame values
		var time_to_decrement = get_one_unit_of_game_time();
		with (player) {
			if (is_carrying_item_in_right_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_item_in_left_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_special_item(obj_clock)) { time_to_decrement = 0; }
		}
		time_remaining -= time_to_decrement;
		if (is_time_up()) {
			killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
			update_death_log(killed_by, difficulty);
			time_remaining = 0; 
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
			if (is_existing_instance(carried_rosary) && player.dead) {
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
				transition = directions.respawn;
				// Destroy or pick up rosary
				if (!carried_rosary.special) { instance_destroy(carried_rosary); } 
				else { with (player) { pick_up_item(carried_rosary, false, carried_dir); } }
			}
			else {
				if (is_game_won()) { update_win_log(difficulty); }
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
}

// DEBUG MODE SPAWNER
if (global.is_test_mode) {
	if (mouse_check_button_pressed(mb_left)) {
		var obj_type = obj_collectable;
		var new_instance = instance_create(mouse_x, mouse_y, obj_type);
		with (new_instance) { move_snap(8, 8); }
	}
	if (mouse_check_button_pressed(mb_right)) {
		var obj_type = obj_clock;
		var new_instance = instance_create(mouse_x, mouse_y, obj_type);
		with (new_instance) { move_snap(8, 8); }
	}
}
