if (process_this_frame()) {
	if (carried) {
		if (time_to_remain_lit > 0) { 
			time_to_remain_lit -= global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps); 
			if (light_source) { light_source.lighting_range = get_scaling_amount(global.controller.PLAYER_LIGHT_RANGE+1, global.controller.TORCH_LIGHT_RANGE, time_to_remain_lit, global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT); }
		}
		else if (!time_to_remain_lit && image_speed > 0) {
		    // Put out torch
		    audio_play_sound( snd_extinguish, 10, false );
		    image_speed = 0;
		    image_index = 1;
		    with light_source { instance_destroy(); }
			light_source = noone;
		}
	}
	else { if (interact_with_torches()) { light_torch(); } }

	event_inherited();
}
