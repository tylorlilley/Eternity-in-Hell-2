/// @function  							obj_door_open();
function obj_door_open() {
	image_index = 1;

	audio_play_sound( snd_open, 10, false );

	with closed { instance_destroy(); }
	closed = noone;

	if (locked) { 
	    global.controller.collected_keys -= 1;
	    door_for_exit.locked = false;
	}
}
