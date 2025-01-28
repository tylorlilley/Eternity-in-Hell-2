event_inherited();

// Spawn chest_obj when destroyed
var controller = global.controller;
if (is_existing_instance(controller)) {
	if (closed) {
		if (contents_obj == obj_statue || contents_obj == obj_fountain) { remains_obj = obj_blood; }
		else if (contents_obj != -1) { 
			controller.current_room.remove_from_instances_at_map_positions(id);
				
			// Spawn content item
			var new_item = noone;
			new_item = instance_create(x, y, contents_obj);
			with (new_item) { become_dropped(id); }
			if (contents_is_special) { with new_item { make_item_special(); } }
		}
	}		
	instance_create(x, y, remains_obj);
}
