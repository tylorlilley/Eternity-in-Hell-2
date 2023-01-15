if (process_this_frame()) {
	event_inherited();

	if (blink_amount > 0) {
		blink_amount -= 1;
	}
	else if (blink_amount == 0) {
		blink_amount = irandom_range(12, 32);
	    play_sound(snd_bumper, true);
		turn_to_face_player();
		if (lethal) {
			lethal = false;
			visible = false;
			killable_by_sword = true;
		}
		else {
			lethal = true;
			visible = true;
			killable_by_sword = false;
		}
	}
	
	image_index = (global.controller.key_up || 
				   global.controller.key_down || 
				   global.controller.key_left || 
				   global.controller.key_right) ? 1 : 0;
	if (lethal && image_index == 1) {
		blink_amount = irandom_range(12, 32);
		turn_to_face_player();
		move_towards_coordinates(global.player.x, global.player.y, true, true);
		move_towards_coordinates(global.player.x, global.player.y, true, true);
	}
}