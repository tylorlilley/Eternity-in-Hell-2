if (process_this_frame()) {
	turn_to_face_player();

	// Disapear and Reappear based on proximity to the player
	if ((get_distance_to_instance(global.player) < global.controller.TRAP_RANGE) != activated) {
		var dropped_meat = get_dropped_meat();
		
		if (dropped_meat == noone || (is_instance_at_coordinates(x, y, dropped_meat))) {
			activated = !activated;
			play_sound(snd_squelch, true);
			if (!activated && dropped_meat == noone) { teleport_to_empty_space(); }
		}
		else { 
			x = dropped_meat.x; 
			y = dropped_meat.y; 
			activated = (get_distance_to_instance(global.player) < global.controller.TRAP_RANGE);
			if (activated) { play_sound(snd_squelch, true); }
		}
	}
	
	event_inherited();
}
