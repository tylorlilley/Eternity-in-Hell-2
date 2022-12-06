if (process_this_frame()) {
	event_inherited();

	turn_to_face_player();
	
	var dropped_meat = noone;
	with (obj_meat) { if (carried == noone) { dropped_meat = self; } }

	// Disapear and Reappear based on proximity to the player
	if (lethal) {
	    if (distance_to_instance(global.player) < MOUTH_DISTANCE && !visible) ||
	       (distance_to_instance(global.player) >= MOUTH_DISTANCE && visible) {
			if (dropped_meat == noone || (instance_at_coordinates(x, y, dropped_meat))) {
		        visible = !visible;
		        play_sound(snd_squelch, true);
				if (!visible && dropped_meat == noone) { teleport_to_empty_space(); }
			}
			else { 
				x = dropped_meat.x; 
				y = dropped_meat.y; 
				visible = distance_to_instance(global.player) < MOUTH_DISTANCE;
				if (visible) { play_sound(snd_squelch, true); }
			}
	    }
	}
	else { visible = false; }
}
