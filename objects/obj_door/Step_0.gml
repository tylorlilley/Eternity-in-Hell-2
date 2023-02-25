if (can_process_this_frame()) {
	event_inherited();
	var player = global.player;
	
	if (is_existing_instance(closed)) {
		// Set up door interaction variables
		var locked = (door_for_exit != -1 && door_for_exit.has_lock), carrying_key = false, push_direction = get_direction_pushed_against(), 
		if (locked) { image_index = 2; }
		with (player) { carrying_key = is_carrying_item(obj_key); }
		
		// Door is being pushed against
		if (push_direction != directions.none) {
		    if (!unlocked_by_key || (locked && !carrying_key)) { 
				play_sound(snd_locked, false);
				with (door_for_exit) { visited = true; }
			}
		    else {
				// Open Door
				with (player) { play_sound(snd_open, true); }
				snap_player_to_position(push_direction);
				move_player(push_direction);
				open_door();
			}
		}
	}
	else if (!stuck_open && !place_meeting(x, y, player)) {
		// Close Door
		play_sound(close_sound, false);
		close_door();
	}
}
