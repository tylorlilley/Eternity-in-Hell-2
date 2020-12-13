if (process_this_frame()) {
	event_inherited();

	turn_to_face_player();

	// Disapear and Reappear based on proximity to the player
	if (lethal) {
	    if (distance_to_instance(global.player) < 40 && !visible) ||
	       (distance_to_instance(global.player) >= 40 && visible) { 
	        visible = !visible;
	        audio_play_sound( snd_squelch, 10, false );
	    }
	}
	else { visible = false; }
}
