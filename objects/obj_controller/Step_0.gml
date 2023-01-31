// If this frame should be processed
var game_manager = global.game_manager;
if (game_manager.number_of_frames_since_game_began % game_manager.FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	var player = global.player, difficulty = global.difficulty;
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
			killed_by = obj_controller;
			update_death_log(killed_by, difficulty);
			time_remaining = 0; 
			play_sound(snd_lose, false); 
		}
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != directions.none && !blackout) { blackout = true; }
		else if (transition != directions.none && blackout) { 
			var next_room = start_room; 
			if (transition == directions.stairs && transitioned_from != noone && transitioned_from.connected_to != noone) {
				next_room = transitioned_from.connected_to.connected_room;
			}
			else if (transition != directions.respawn) {  next_room = current_room.adj_rooms[transition]; }
			transition_to_room(next_room); 
		}
	}
	if (room != rm_finish && (is_game_lost() || is_game_won())) {
		if (is_game_won() || is_time_up() || death_timer == 0) {
			var carried_rosary = noone, carried_dir = directions.none;
			with (player) { 
				carried_rosary = get_carried_item(obj_rosary);
				carried_dir = (right_hand_item == carried_rosary) ? directions.right : directions.left;
				put_down_item(right_hand_item, false);
				put_down_item(left_hand_item, false);
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
					depth = -10;
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
	var new_color = make_color_rgb(floor(get_scaling_amount(0, 255, power(1-(time_remaining/time_provided), 8), 1)), 0, 0);
	if (flash_time > 0) { 
		new_color = merge_color(new_color, c_white, power(flash_time, 2)/power(SCREEN_FLASH_DURATION, 2));
		flash_time -= 1;
		if (flash_time == SCREEN_FLASH_DURATION) { screen_flash = false; }
	}
	global.bg_color = new_color;
	
	// Restart game if necessary
	if key_enter_released { 
		play_sound(snd_move, false);
		restart_game();
	}
	
	// ALL CODE CHECKING FOR KEYS DURING THIS FRAME MUST HAPPEN BEFORE THIS POINT
	clear_inputs_for_next_frame();
}

// Record inputs that happen between frames to apply to the next frame
set_up_inputs_for_next_frame();
