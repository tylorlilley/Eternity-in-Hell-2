if (process_this_frame()) {
	if (time_to_remain_lit > 0) { time_to_remain_lit -= 1/game_get_speed(gamespeed_fps); }
	else if (!time_to_remain_lit && image_speed > 0) {
	    // Put out torch
	    audio_play_sound( snd_extinguish, 10, false );
	    image_speed = 0;
	    image_index = 1;
	    with light_source { instance_destroy(); }
	}

	set_instance_to_same_position(light_source);

	event_inherited();
}
