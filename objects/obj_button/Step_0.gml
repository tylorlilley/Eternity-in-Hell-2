event_inherited();

if (can_press_button()) {
		with (obj_portcullis) { stuck_open = true; open_door(); }
		flip_sprite_at_random(true);
		play_sound(snd_shovel, true);
		image_index = 1;
		visible = true;
}