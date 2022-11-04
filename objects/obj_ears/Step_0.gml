if (process_this_frame()) {
	event_inherited();
	
	if (awake && !instance_at_coordinates(target_x, target_y, self)) {
		sprite_index = spr_ears_awake;
		image_index = (x > target_x) ? 1 : -1;
		move_towards_coordinates(target_x, target_y);
		move_towards_coordinates(target_x, target_y);
		move_towards_coordinates(target_x, target_y);
		move_towards_coordinates(target_x, target_y);
		if (hiss_timer >= 0) { hiss_timer -= 1; }
		if (hiss_timer == 0 && !audio_is_playing(snd_ears)) { play_sound(snd_ears, false); }
	}
	else {
		sprite_index = spr_ears;
		awake = false;
	}
}