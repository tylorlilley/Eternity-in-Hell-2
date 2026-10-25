with (obj_echo) { 
	instance_destroy();
	if (global.player.dead) { play_sound(snd_impact, false); }
}
