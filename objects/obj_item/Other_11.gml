/// @description Step
event_inherited();

// A dropped item is destroyed by lava
if (!is_existing_instance(holder) && is_lava_at_position(x, y)) {
	instance_destroy();
	play_sound(snd_extinguish, true);
	global.controller.evaluation_manager.increment_evaluation_variable("item_lava_count");
}

// A clock's sand and a compass's hands are drawn over the item, so keep their frame up to date
if (sprite_index == get_sprite_to_use(spr_clock) || 
	sprite_index == get_sprite_to_use(spr_clock_farmer) ||
	sprite_index == get_sprite_to_use(spr_compass)) {
	var _prev_time_image_index = time_image_index;
	if (sprite_index == get_sprite_to_use(spr_compass)) {
		// The hands point at the compass's target; -1 means the player is on it, so they stay as they were
		var _new_image_index = get_compass_image_index();
		time_image_index = (_new_image_index == -1) ? time_image_index : _new_image_index;
		time_sprite_index = get_sprite_to_use(spr_compass_hands);
	}
	else {
		// The sand follows the time elapsed
		time_image_index = get_clock_image_index();
		time_sprite_index = get_sprite_to_use(spr_clock_sand);
	}
	
	// Tick whenever the sand or hands move to a new frame
	if (time_image_index != _prev_time_image_index) {
		play_sound(snd_clock_tick, false);
	}
}


