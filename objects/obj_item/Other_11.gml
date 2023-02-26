/// @description Step
event_inherited();
	
if (!is_existing_instance(holder) && is_lava_at_position(x, y)) {
	instance_destroy();
	play_sound(snd_extinguish, true);
}
