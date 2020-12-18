if (process_this_frame()) {
	event_inherited();
	
	if closed {
		if locked image_index = 2;
		var push_direction = pushed_against_by_player(true);
		if (push_direction != noone || instance_place(x, y, obj_player)) {
			var carried_key = get_carried_item_of_type(obj_key);
		    if (locked && !carried_key) { audio_play_sound( snd_locked, 10, false ); }
		    else { 
				open_door(); 
				move_player(push_direction); 
				if locked {
					door_for_exit.locked = false;
					locked = false;
					audio_play_sound(snd_mana, 10, false);
					with carried_key { if (!special) { instance_destroy(); } }
				}
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
