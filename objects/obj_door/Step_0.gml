if (can_process_this_frame()) {
	event_inherited();
	
	if (is_existing_instance(closed)) {
		if (locked) { image_index = 2; }
		var push_direction = get_direction_pushed_against();
		var carrying_key = false;
		with (global.player) { carrying_key = is_carrying_item(obj_key); }
		if (!is_existing_instance(global.player.moved_by) && push_direction != directions.none) {
		    if (!unlocked_by_key || (locked && !carrying_key)) { play_sound(snd_locked, false); }
		    else {
				play_sound(snd_open, true);
				snap_player_to_position(push_direction);
				move_player(push_direction);
				open_door();
			}
		}
	}
	else if (!stuck_open && !place_meeting(x, y, global.player)) {
		play_sound(close_sound, false);
		close_door();
	}
}
