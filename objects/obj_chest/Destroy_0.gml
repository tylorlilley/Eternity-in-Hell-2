event_inherited();

// Spawn chest_obj when destroyed
var remains_obj = obj_dirt, controller = global.controller;
if (is_existing_instance(controller)) {
	if (closed) {
		var contents_obj = controller.current_room.chest_obj;
		if (contents_obj == obj_statue) { remains_obj = obj_blood; }
		else if (contents_obj != -1) { 
			controller.current_room.remove_from_instances_at_map_positions(id);
				
			// Spawn content item
			var new_item = noone;
			new_item = instance_create(x, y, contents_obj); // Sometimes spawn fountains too?
			with (new_item) { become_dropped(id); }
			if (controller.current_room.has_special_item) { with new_item { make_item_special(); } }
		}
	}		
	instance_create(x, y, remains_obj);
}
