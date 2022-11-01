/// @function								move_player(dir);
/// @param		{direction} dir				The direction to move the player instance
function move_player(dir) {
	with global.player {
		// Move player
		if (dir != directions.stairs) {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
			move_in_direction(dir, true);
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
	if (carried_items[dir]) { with carried_items[dir] { drop_item(dir, true); } }
	else {
		var dropped_items = instance_place_all(x, y, obj_item);
		while (array_length(dropped_items) > 0) {
			var dropped_item = array_random_pop(dropped_items);
			if (dropped_item && !dropped_item.carried && dropped_item.can_pick_up && instance_at_coordinates(x, y, dropped_item)) {
				with dropped_item { pick_up_item(dir, true, global.player); return true; }
			}
		}
		return false;
	}
}

/// @function								get_carried_item_of_type(dir);
/// @param		{index} obj_index			The object type to check the carried items for
function get_carried_item_of_type(obj_index) {
	var carried_item = noone;
	for (var i = 0; i <= 4; i += 1;) {
		var current_item = global.player.carried_items[i];
		if (current_item && current_item.object_index == obj_index) { 
			if (!carried_item || (current_item.special && !carried_item.special)) {
				carried_item = current_item;
			}
		}
	}
	return carried_item;
}

/// @function								create_item_in_hand(dir);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
/// @param		{index} obj_index			The type of item to create in hand
function create_item_in_hand(dir, obj_index)	{
	var new_item = instance_create_depth(global.player.x, global.player.y, -5, obj_index)
	with new_item { pick_up_item(dir, false, global.player); }
	return new_item;
}

/// @function								kill_player();
function kill_player() {
	// Drop all carried items
	//drop_all_items();
	
	// Set variables to mark death
	global.player.dead = true;
	global.controller.death_timer = 40;
	audio_play_sound( snd_lose, 10, false );
}

/// @function								drop_all_items()
function drop_all_items() {
	for (var i = 1; i <= 3; i += 2;) {
		if (global.player.carried_items[i]) { with global.player.carried_items[i] { drop_item(i, false); } }
	}
}