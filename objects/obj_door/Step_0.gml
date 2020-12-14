if (process_this_frame()) {
	event_inherited();
	
	if closed {
		if locked image_index = 2;
		var push_direction = pushed_against_by_player(true);
		if (push_direction != noone || instance_place(x, y, obj_player)) {
		        if (locked && global.controller.collected_keys <= 0) { audio_play_sound( snd_locked, 10, false ); }
		        else { 
					open_door(); 
					move_player(push_direction); 
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
