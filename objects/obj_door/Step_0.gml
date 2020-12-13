if (process_this_frame()) {
	event_inherited();
	

	if closed {
	    if locked image_index = 2;
	    if ((instance_at_coordinates(global.player.x_prev, global.player.y_prev-16, self) && global.controller.key_up_pressed) ||
	       (instance_at_coordinates(global.player.x_prev, global.player.y_prev+16, self) && global.controller.key_down_pressed) || 
	       (instance_at_coordinates(global.player.x_prev-16, global.player.y_prev, self) && global.controller.key_left_pressed) ||
	       (instance_at_coordinates(global.player.x_prev+16, global.player.y_prev, self) && global.controller.key_right_pressed) ||
	       instance_place(x, y, obj_player)) {
	           if (locked && global.controller.collected_keys <= 0) { audio_play_sound( snd_locked, 10, false ); }
	           else { open_door(); }
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
