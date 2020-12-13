/// @function								rustle_bush();
function rustle_bush() {
	image_xscale *= -1;
	occupied = !occupied;
	audio_play_sound( snd_bush, 10, false );
}
