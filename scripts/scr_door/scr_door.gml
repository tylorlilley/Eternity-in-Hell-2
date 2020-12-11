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
	
	close_behind = false;
}

/// @function							obj_door_close();
///	@param		{boolean}	room_start	Whether or not this is being lit by the game upon room initialization
function obj_door_close(room_start) {
	image_index = 0;
	
	if !room_start { audio_play_sound( snd_open, 10, false ); }
	
	closed = instance_create_depth(x, y, 0, obj_solid);
	closed.visible = false;
}
