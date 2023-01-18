if (process_this_frame()) {
	if (blink_amount > 0) {
		blink_amount -= 1;
	}
	else if (blink_amount == 0) {
		blink_amount = irandom_range(12, 32);
	    play_sound(snd_eyes, true);
		turn_to_face_player();
		activated = !activated;
	}
	
	image_index = (global.controller.key_up || 
				   global.controller.key_down || 
				   global.controller.key_left || 
				   global.controller.key_right) ? 1 : 0;
	if (activated && image_index == 1) {
		blink_amount = irandom_range(12, 32);
		turn_to_face_player();
		// TODO: Explore making corporeal if we create better pathfinding for this function
		move_towards_coordinates(global.player.x, global.player.y, true, true);
		move_towards_coordinates(global.player.x, global.player.y, true, true);
	}
	
	event_inherited();
}