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

/// @function							open_portcullis();
function open_portcullis() {
	door_for_exit.open_portcullis();
	stuck_open = true;
	open_door();
}

/// @function								break_heart_case();
///	@param		{bool}	  destroy_self		Whether to flash the screen or not
function break_heart_case(has_screen_flash) {
	instance_create(x, y, obj_dirt);
	var new_plate = instance_create(x, y, obj_heart_plate);
	var new_heart = instance_create(x, y, obj_heart);
	new_heart.image_index = image_index;
	global.controller.current_room.add_to_instances_at_map_positions(new_heart);
	instance_destroy();
	
	if (has_screen_flash) { with (new_plate) { screen_flash(); } }
}