event_inherited();

image_speed = 1;

dir = -1;

if (global.difficulty < difficulties.medium) {
	instance_create(x, y, obj_skeleton); 
	instance_destroy();
}
else { play_sound(snd_hiss, false); }
