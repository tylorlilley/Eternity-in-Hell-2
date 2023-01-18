if (process_this_frame()) {
	if (awake && !is_instance_at_coordinates(target_x, target_y, self)) {
		sprite_index = spr_ears_awake;
		set_farm_mode_sprite(spr_ears_awake_farmer);
		image_index = (x > target_x) ? 1 : -1;
		// TODO: Explore making corporeal again if we create better pathfinding for this function
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		if (hiss_timer >= 0) { hiss_timer -= 1; }
		if (hiss_timer == 0 && !audio_is_playing(snd_ears)) { play_sound(snd_ears, false); }
	}
	else {
		sprite_index = spr_ears;
		set_farm_mode_sprite(spr_ears_farmer);
		awake = false;
	}
	
	event_inherited();
}