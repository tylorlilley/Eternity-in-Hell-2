// Destroying the generator destroys all its echoes, and each makes an impact sound if the player died
with (obj_echo) { 
	instance_destroy();
	if (global.player.dead) { play_sound(snd_impact, false); }
}