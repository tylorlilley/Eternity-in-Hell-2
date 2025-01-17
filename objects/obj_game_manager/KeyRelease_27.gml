if (escaped) { game_end(); }
else { 
	paused = true; 
	escaped = true; 
	play_sound(snd_putdown, false); 
	with (obj_projectile) { speed = prev_speed; }
}