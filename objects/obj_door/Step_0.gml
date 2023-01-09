if (process_this_frame()) {
	event_inherited();
	
	if closed {
		if locked image_index = 2;
		var push_direction = pushed_against_by_player(true);
		if (push_direction != noone) {
			var carried_key = get_carried_item_of_type(obj_key);
		    if (locked && !carried_key) { play_sound(snd_locked, false); }
		    else if (!global.player.opened_door_this_frame) {
				global.player.opened_door_this_frame = true;
				play_sound(snd_open, true);
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
