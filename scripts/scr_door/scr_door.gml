/// @function  							open_door();
function open_door() {
	image_index = 1;

	with closed { instance_destroy(); }
	closed = noone;
	
	if locked {
		locked = false;
		with (global.player) { play_sound(snd_mana, true); }
		with door_for_exit { unlock(); }
		with (get_carried_item_of_type(obj_key)) { if (!special) { instance_destroy(); } }
	}
}

/// @function							close_door();
function close_door() {
	image_index = 0;
	
	closed = instance_create_depth(x, y, 0, obj_solid);
	closed.visible = false;
}
