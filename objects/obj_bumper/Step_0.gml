if (process_this_frame()) {
	event_inherited();

	if (trap_duration == -1 && trap && distance_to_instance(global.player) <= 40) { 
	    audio_play_sound( snd_bumper, 10, false );
	    lethal = true;
		trap = false;
		visible = true;
		turn_to_face_player();
		trap_duration = 60*3;
	}
	if (trap_duration > 0) {
		trap_duration -= 1;
	}
	else if (trap_duration == 0) {
		audio_play_sound( snd_bumper, 10, false );
	    lethal = false;
		trap = true;
		visible = false;
	}
}