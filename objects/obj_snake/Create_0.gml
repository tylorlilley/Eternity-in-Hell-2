event_inherited();

can_move_on_border = true;
image_speed = 1;

dir = directions.none;

if (global.difficulty < difficulties.medium) {
	instance_create(x, y, obj_skeleton); 
	instance_destroy();
}
else { play_sound(snd_hiss, false); }
