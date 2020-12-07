event_inherited();

if (lethal && instance_place(x, y, global.player) && !global.player.dead) {
    global.player.dead = true;
	audio_play_sound( snd_lose, 10, false );
	audio_play_sound( death_sound, 10, false );
}

