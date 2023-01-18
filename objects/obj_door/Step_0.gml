if (process_this_frame()) {
	event_inherited();
	
	if (closed != noone) {
		if (locked) { image_index = 2; }
		var push_direction = pushed_against_by_player();
		if (push_direction != noone) {
			var carried_key = get_carried_item_of_type(obj_key);
		    if (!unlocked_by_key || (locked && !carried_key)) { play_sound(snd_locked, false); }
		    else {
				play_sound(snd_open, true);
				global.player.x = x;
				global.player.y = y;
				switch (push_direction) {
					case directions.up: { global.player.y += 16; break; }
					case directions.down: { global.player.y -= 16; break; }
					case directions.left: { global.player.x += 16; break; }
					case directions.right: { global.player.x -= 16; break; }
				}
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
