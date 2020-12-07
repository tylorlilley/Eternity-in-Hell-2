/// @function								obj_bush_rustle();
function obj_bush_rustle() {
	image_xscale *= -1;
	occupied = !occupied;
	audio_play_sound( snd_bush, 10, false );
}
