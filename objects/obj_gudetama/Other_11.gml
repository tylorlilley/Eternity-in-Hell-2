/// @description Step

event_inherited();

if (can_process_this_frame()) {
	if (image_speed != 0 && is_solid_at_position(x, y)) { image_speed = 0; play_sound(snd_give_up, false); }
}