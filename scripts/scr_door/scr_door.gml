/// @function  							open_door();
function open_door() {
	image_index = 1;

	with closed { instance_destroy(); }
	closed = noone;
	close_behind = false;
	
	if locked {
		locked = false;
		with (global.player) { play_sound(snd_mana, true); }
		with door_for_exit { unlock(); }
		with (get_carried_item_of_type(obj_key)) { if (!special) { instance_destroy(); } }
	}
}

/// @function							close_door();
///	@param		{boolean}	room_start	Whether or not this is being lit by the game upon room initialization
function close_door(room_start) {
	image_index = 0;
	
	if !room_start { play_sound( snd_close, false ); }
	
	closed = instance_create_depth(x, y, 0, obj_solid);
	closed.visible = false;
}
