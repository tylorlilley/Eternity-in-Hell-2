/// @description Step
event_inherited();
prev_image_index = image_index;

if (!is_existing_instance(holder) && is_lava_at_position(x, y)) {
	instance_destroy();
	play_sound(snd_extinguish, true);
}

// Draw Clock Time
if (sprite_index == get_sprite_to_use(spr_clock) || 
	sprite_index == get_sprite_to_use(spr_clock_farmer) ||
	sprite_index == get_sprite_to_use(spr_compass)) {
	// Update drawn sand and hands for clock and compass sprites
	var prev_time_image_index = time_image_index;
	if (sprite_index == get_sprite_to_use(spr_compass)) {
		time_image_index = get_compass_image_index();
		time_sprite_index = get_sprite_to_use(spr_compass_hands);
	}
	else {
		time_image_index = get_clock_image_index();
		time_sprite_index = get_sprite_to_use(spr_clock_sand);
		if (special) { 
			time_sprite = (sprite_index == spr_clock) ? spr_special_clock_sand : spr_special_clock_sand_farmer; 
		}
	}
	
	if (time_image_index != prev_time_image_index) {
		play_sound(snd_clock_tick, false);
	}
}
