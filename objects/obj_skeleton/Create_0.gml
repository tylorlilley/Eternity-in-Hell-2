event_inherited();

killable_by_sword = true;
consumed_by_block = true;
death_sound = snd_crunch;
image_speed = 1;

usurped = get_random_chance_out_of(31);
if (usurped) {
	instance_create_depth(x, y, 0, obj_bumper);
	instance_destroy();
}