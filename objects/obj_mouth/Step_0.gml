if (process_this_frame()) {
	turn_to_face_player();

	// Disapear and Reappear based on proximity to the player
	if ((distance_to_instance(global.player) < global.controller.TRAP_RANGE) != activated) {
		var dropped_meat = noone;
		with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
		
		if (dropped_meat == noone || (instance_at_coordinates(x, y, dropped_meat))) {
			activated = !activated;
			play_sound(snd_squelch, true);
			if (!activated && dropped_meat == noone) { teleport_to_empty_space(); }
		}
		else { 
			x = dropped_meat.x; 
			y = dropped_meat.y; 
			activated = (distance_to_instance(global.player) < global.controller.TRAP_RANGE);
			if (activated) { play_sound(snd_squelch, true); }
		}
	}
	
	event_inherited();
}
