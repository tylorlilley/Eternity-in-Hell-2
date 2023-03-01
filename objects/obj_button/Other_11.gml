/// @description Step
event_inherited();

if (can_press_button() && image_index == 0) {
		with (obj_portcullis) { open_portcullis(); }
		flip_sprite_at_random(true);
		play_sound(snd_shovel, true);
		image_index = 1;
		visible = true;
}