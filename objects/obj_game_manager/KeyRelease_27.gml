if (paused) { game_end(); }
else { 
	paused = true;
	play_sound(snd_pickup, false); 
	with (obj_projectile) { speed = prev_speed; }
}