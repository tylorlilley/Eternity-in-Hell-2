/// @function  							open_door();
function open_door() {
	image_index = 1;

	audio_play_sound( snd_open, 10, false );

	with closed { instance_destroy(); }
	closed = noone;
	
	close_behind = false;
}

/// @function							close_door();
///	@param		{boolean}	room_start	Whether or not this is being lit by the game upon room initialization
function close_door(room_start) {
	image_index = 0;
	
	if !room_start { audio_play_sound( snd_open, 10, false ); }
	
	closed = instance_create_depth(x, y, 0, obj_solid);
	closed.visible = false;
}
