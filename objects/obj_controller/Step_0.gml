// If this frame should be processed
if (number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	if (!game_has_been_lost() && !game_has_been_won()) {
	    // Play map Sound Effects
	    if key_space_pressed { play_sound( snd_pickup, false ); }
	    if key_space_released { play_sound( snd_putdown, false ); }
    
	    // Update per frame values
		var time_to_decrement = one_unit_of_game_time();
		with (global.player) {
			if (is_carrying_item_in_right_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_item_in_left_hand(obj_clock)) { time_to_decrement/= 2; }
			if (is_carrying_special_item(obj_clock)) { time_to_decrement = 0; }
		}
		time_remaining -= time_to_decrement;
	    if (game_has_timed_out()) {
			killed_by = obj_controller;
			update_death_log(global.controller.killed_by, global.difficulty);
			time_remaining = 0; 
			play_sound(snd_lose, false); 
		}
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != noone && !blackout) { blackout = true; }
		else if (transition != noone && blackout) { 
			var next_room = start_room; 
			 if (transition == 4 && transition_hole != noone) {  next_room = transition_hole.connected_hole.connected_room; }
			 else if (transition != 5) {  next_room = current_room.adj_rooms[transition]; }
			transition_to_room(next_room); 
		}
	}
	if (room != rm_finish && (game_has_been_lost() || game_has_been_won())) {
		if (game_has_been_won() || game_has_timed_out() || death_timer == 0) {
			var carried_rosary = noone, carried_dir = noone;
			with (global.player) { 
				carried_rosary = get_carried_item(obj_rosary);
				carried_dir = (right_hand_item == carried_rosary) ? directions.right : directions.left;
				put_down_item(right_hand_item, false);
				put_down_item(left_hand_item, false);
			}
			if (carried_rosary != noone && global.player.dead) {
				// Revive and respawn player
				with (global.player) {
					x = -8;
					y = -8;
					dead = false;
					image_index = 0;
					var player_corpse = instance_create_depth(x, y, 0, obj_player_corpse);
					player_corpse.image_xscale = image_xscale;
				}				
				transition = directions.respawn;
				// Destroy or pick up rosary
				if (!carried_rosary.special) { instance_destroy(carried_rosary); } 
				else { with (global.player) { pick_up_item(carried_rosary, false, carried_dir); } }
			}
			else {
				if (game_has_been_won()) { update_win_log(global.difficulty); }
				with (global.player) {
					visible = false;
					room_goto(rm_finish);
				}
			}
		}
		else { death_timer -= 1; }
	}
	
	// Update background color
	bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(time_remaining/time_provided), 8), 1)), 20, 20);
	
	// Restart game if necessary
	if key_enter_released { 
		play_sound(snd_move, false);
		restart_game();
	}
	
	// ALL CODE CHECKING FOR KEYS DURING THIS FRAME MUST HAPPEN BEFORE THIS POINT
	clear_inputs_for_next_frame();
}

// Increment number of processed frames
number_of_frames_since_game_began += 1;

// Record inputs that happen between frames to apply to the next frame
get_inputs_for_next_frame();