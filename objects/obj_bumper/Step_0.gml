if (process_this_frame()) {
	event_inherited();


	if (blink_amount > 0) {
		blink_amount -= 1;
	}
	else if (blink_amount == 0) {
		blink_amount = irandom_range(6, 16);
	    audio_play_sound( snd_bumper, 10, false );
		turn_to_face_player();
		if (lethal) {
			lethal = false;
			visible = false;
		}
		else {
			lethal = true;
			visible = true;
		}
	}
	
	if (lethal && 
		(global.controller.key_up || 
		global.controller.key_down || 
		global.controller.key_left || 
		global.controller.key_right)) {
		blink_amount = irandom_range(6, 16);
		//audio_play_sound( snd_bumper, 10, false );
		turn_to_face_player();
		move_towards_coordinates(global.player.x, global.player.y);
	}
}