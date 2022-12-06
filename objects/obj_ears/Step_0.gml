if (process_this_frame()) {
	event_inherited();
	
	var dropped_meat = noone;
	with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
	if (dropped_meat) { target_x = dropped_meat.x; target_y = dropped_meat.y; }
	
	if (awake && !instance_at_coordinates(target_x, target_y, self)) {
		sprite_index = (global.controller.FARM_MODE) ? spr_ears_awake_farmer : spr_ears_awake;
		image_index = (x > target_x) ? 1 : -1;
		// TODO: Explore making killable by block and lava again? Probably means not attracted to splash sound
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		move_towards_coordinates(target_x, target_y, true, true);
		if (hiss_timer >= 0) { hiss_timer -= 1; }
		if (hiss_timer == 0 && !audio_is_playing(snd_ears)) { play_sound(snd_ears, false); }
	}
	else {
		sprite_index = spr_ears;
		sprite_index = (global.controller.FARM_MODE) ? spr_ears_farmer : spr_ears;
		awake = false;
	}
}