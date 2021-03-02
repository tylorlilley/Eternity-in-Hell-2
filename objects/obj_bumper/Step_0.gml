if (process_this_frame()) {
	event_inherited();

	if (trap && distance_to_instance(global.player) <= 40) { 
	    audio_play_sound( snd_bumper, 10, false );
	    lethal = true;
		trap = false;
		visible = true;
		turn_to_face_player();
	}
}