if (x < 0 && y < 0 && !activated) { teleport_to_empty_space(); }

if (can_process_this_frame()) {
	turn_to_face_player();

	// Disapear and Reappear based on proximity to the player
	var player = global.player;
	if ((get_distance_to_instance(player) < TRAP_RANGE) != activated) {
		var dropped_meat = get_dropped_meat();
		
		if (!is_existing_instance(dropped_meat) || (is_instance_at_coordinates(x, y, dropped_meat))) {
			activated = !activated;
			play_sound(snd_squelch, true);
			if (!activated && !is_existing_instance(dropped_meat)) { teleport_to_empty_space(); }
		}
		else { 
			x = dropped_meat.x; 
			y = dropped_meat.y; 
			activated = (get_distance_to_instance(player) < TRAP_RANGE);
			if (activated) { play_sound(snd_squelch, true); }
		}
	}
	
	event_inherited();
}
