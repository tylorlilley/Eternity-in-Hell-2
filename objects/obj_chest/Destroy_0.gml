event_inherited();

// Spawn contents when destroyed
var _controller = global.controller;
if (is_existing_instance(_controller)) {
	if (closed) {
		if (contents_obj == obj_statue || contents_obj == obj_fountain) { remains_obj = obj_blood; }
		else if (contents_obj != -1) { 
			_controller.current_room.remove_from_instances_at_map_positions(id);
				
			// Spawn content item
			var _new_item = noone;
			_new_item = instance_create(x, y, contents_obj);
			with (_new_item) { become_dropped(id); }
			if (contents_is_special) { with _new_item { make_item_special(); } }
		}
	}		
	instance_create(x, y, remains_obj);
}
