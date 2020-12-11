if (process_this_frame()) {
	event_inherited();

	var player = instance_place(x, y, global.player);
	if (lethal && player && !global.player.dead) {
		global.player.dead = true;
		audio_play_sound( snd_lose, 10, false );
		audio_play_sound( death_sound, 10, false );
	}
}
