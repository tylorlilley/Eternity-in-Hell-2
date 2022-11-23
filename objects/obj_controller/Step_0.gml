// If this frame should be processed
if (number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	if (!game_has_been_lost() && !game_has_been_won()) {
	    // Play map Sound Effects
	    if key_space_pressed { play_sound( snd_pickup, false ); }
	    if key_space_released { play_sound( snd_putdown, false ); }
    
	    // Update per frame values
	    time_remaining -= one_unit_of_game_time();
	    //if key_space { time_remaining -= one_unit_of_game_time(); }
	    if (game_has_timed_out()) { time_remaining = 0; play_sound(snd_lose, false); }
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != noone && !blackout) { blackout = true; }
		else if (transition != noone && blackout) { 
			var next_room = (transition == 5) ? start_room : current_room.adj_rooms[transition]
			transition_to_room(next_room); 
		}
	}
	if (room != rm_finish && (game_has_been_lost() || game_has_been_won())) {
		if (game_has_been_won() || game_has_timed_out() || death_timer == 0) {
			var carried_rosary = get_carried_item_of_type(obj_rosary);
			var carried_pos = global.player.carried_items[1] == carried_rosary ? 1 : 3;
			if (carried_rosary && global.player.dead) {
				// Destroy the rosary being used
				transition = 5;
				with global.player {
					drop_all_items();
					dead = false;
					image_index = 0;
					var player_corpse = instance_create_depth(x, y, 3, obj_player_corpse);
					player_corpse.image_xscale = image_xscale;
				}
				with carried_rosary { 
					if (!special) { instance_destroy(); } 
					else { pick_up_item(carried_pos, false, global.player); }
				}
			}
			else {
				with (global.player) {
					drop_all_items();
					visible = false;
					room_goto(rm_finish);
				}
			}
		}
		else { death_timer -= 1; }
	}
	
	// Update background
	background_id = layer_background_get_id(layer_get_id("Background"));
	bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(time_remaining/time_provided), 8), 1)), 20, 20);
	//if (game_has_been_won()) { bg_color = c_white; }
	layer_background_blend( background_id,  bg_color );
	
	// Restart game if necessary
	if key_enter_released { 
		play_sound(snd_move, false);
		if (game_has_been_won() && global.difficulty == difficulties.very_hard) { 
			ini_open("farmer_mode_unlocked.ini");
			ini_write_string("modes", "farmer", true);
			ini_close();
		}
		restart_game();
	}
	
	// ALL CODE CHECKING FOR KEYS DURING THIS FRAME MUST HAPPEN BEFORE THIS POINT
	clear_inputs_for_next_frame();
}

// Increment number of processed frames
number_of_frames_since_game_began += 1;

// Record inputs that happen between frames to apply to the next frame
get_inputs_for_next_frame();