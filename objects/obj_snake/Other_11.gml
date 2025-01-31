/// @description End Step
var move_speed = get_random_chance_out_of(SNAKE_MOVE_FREQUENCY) ? 2 : 1;
var prev_dir = dir, prev_image_xscale = image_xscale;
move_snake(move_speed);
	
if (get_random_chance_out_of(SNAKE_HISS_FREQUENCY)) { play_sound(snd_hiss, false); }

if (prev_dir == dir) { image_xscale = -prev_image_xscale; }
else { image_xscale = 1; image_yscale = 1; image_angle = dir * -90; }
	
event_inherited();
