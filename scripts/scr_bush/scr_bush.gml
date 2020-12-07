/// @function								obj_bush_rustle();
function obj_bush_rustle() {
	image_xscale *= -1;
	occupied = !occupied;
	sound_play(snd_bush);
}
