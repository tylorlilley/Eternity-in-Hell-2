/// @function								move_player(dir);
/// @param		{direction} dir				The direction to move the player instance
function move_player(dir) {
	with global.player {
		// Move player
		if (dir != directions.stairs) {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
			move_in_direction(dir);
		}
		// Move carried items
		for (var i = 0; i <= 4; i += 1;) {
			if (carried_items[i]) { set_instance_to_same_position(carried_items[i]); }
		}
	}
}

/// @function								pick_up_or_drop_item(dir);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
function pick_up_or_drop_item(dir) {
	if (carried_items[dir]) { with carried_items[dir] { drop_item(dir); } }
	else {
		var dropped_items = ds_list_create();
		instance_place_list(x, y, obj_item, dropped_items, false);
		while (ds_list_size(dropped_items) > 0) {
			var dropped_item = ds_list_pop_random_value(dropped_items);
			if (dropped_item && !dropped_item.carried && instance_at_coordinates(x, y, dropped_item)) {
				with dropped_item { pick_up_item(dir); ds_list_destroy(dropped_items); return true; }
			}
		}
		ds_list_destroy(dropped_items);
		return false;
	}
}

function get_carried_item_of_type(obj_index) {
	var carried_item = noone;
	for (var i = 0; i <= 4; i += 1;) {
		var carried_item = global.player.carried_items[i];
		if (carried_item && carried_item.object_index == obj_index) { carried_key = carried_item; break; }
	}
	return carried_item;
}