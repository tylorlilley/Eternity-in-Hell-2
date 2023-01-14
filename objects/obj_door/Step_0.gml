if (process_this_frame()) {
	event_inherited();
	
	if closed {
		if locked image_index = 2;
		var push_direction = pushed_against_by_player();
		if (push_direction != noone) {
			var carried_key = get_carried_item_of_type(obj_key);
		    if (locked && !carried_key) { play_sound(snd_locked, false); }
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
	else {
		if (close_behind && !instance_place(x, y, global.player)) {
			close_door(false);
		}
		else if (!close_behind && instance_place(x, y, global.player)) {
			close_behind = true;
		}
	}
	
}
