/// @function  							open_door();
function open_door() {
	image_index = 1;

	with closed { instance_destroy(); }
	closed = noone;
	depth = CROSS_DEPTH;
	
	if (door_for_exit != -1 && door_for_exit.has_lock) {
		door_for_exit.unlock();
		with (global.player) { 
			play_sound(snd_mana, true);
			with (get_carried_item(obj_key)) { if (!special) { instance_destroy(); } }
		}
	}
}

/// @function							close_door();
function close_door() {
	image_index = 0;
	
	closed = instance_create(x, y, obj_solid);
	closed.visible = false;
	depth = SOLID_DEPTH;
}
