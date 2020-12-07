/// @function  							obj_door_open();
function obj_door_open() {
	image_index = 1;

	sound_play(snd_open);

	with closed { instance_destroy(); }
	closed = noone;

	if (locked) { 
	    global.controller.collected_keys -= 1;
	    door_for_exit.locked = false;
	}
}
