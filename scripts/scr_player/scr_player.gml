/// @function								move_player(dir);
/// @param		{direction} dir				The direction to move the player instance
function move_player(dir) {
	with global.player {
		// Move player
		if (dir != directions.stairs) {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
			move_in_direction(dir, true);
			with (obj_echo_spot) { array_push(moves, dir); }
		}
		// Move carried items
		for (var i = 0; i <= 4; i += 1;) {
			if (instance_exists(carried_items[i])) { 
				set_instance_to_same_position(carried_items[i]);
				if (carried_items[i].object_index == obj_torch) { set_instance_to_same_position(carried_items[i].light_source); }
			}
		}
	}
}

/// @function								pick_up_or_drop_item(dir);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
function pick_up_or_drop_item(dir) {
	if (carried_items[dir]) {
		if (carried_items[dir].object_index == obj_meat) {
			with (obj_spider) { if (lethal) { audio_play_sound_for_object_only_once(snd_lose); } }
		}
		// Drop Item and alert one obj_hands to come grab it
		var possible_hands = array_create(0);
		with (obj_hands) { if (visible) { array_push(possible_hands, self); } }
		var new_hands = array_length(possible_hands) > 0 ? array_random_get(possible_hands) : noone;
		with new_hands { target_item = other.carried_items[dir]; }
		with carried_items[dir] { drop_item(dir, true); }
	}
	else {
		// Cycle through the items you could be possibly pickiung up
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
	play_sound(snd_lose, true);
	with (obj_echo_spot) { instance_destroy(); }
}

/// @function								drop_all_items()
function drop_all_items() {
	for (var i = 1; i <= 3; i += 2;) {
		if (global.player.carried_items[i]) { with global.player.carried_items[i] { drop_item(i, false); } }
	}
}

/// @function								get_direction_input(key_pressed_only)
/// @param		{bool} key_pressed_only		Whether to only count if the key has been pressed this frame
/// @param		{bool} ignore_solid			Whether to ignore solids when determininig if dir is valid
function get_direction_input(key_pressed_only, ignore_solid) {
	// Return no input if player is dead or looking at map
	if (global.player.dead || global.controller.key_space) { return noone; }
	
	// Starting with the previous direction, check each direction for inputs
	var possible_directions = array_create(0);
	for (var i = 0; i < 4; i++) {
		var current_dir = (i+global.player.dir_prev) % 4;
		
		if (!can_move_in_direction(current_dir, ignore_solid, true)) { continue; }
		
		if current_dir == directions.up &&
			global.controller.key_up && 
			!global.controller.key_down &&
			(global.controller.key_up_pressed || !global.controller.key_up_released) &&
			(!key_pressed_only || global.controller.key_up_pressed) { 
				array_push(possible_directions, directions.up); 
		}
		else if current_dir == directions.down &&
				global.controller.key_down && 
				!global.controller.key_up &&
				(global.controller.key_down_pressed || !global.controller.key_down_released) &&
				(!key_pressed_only || global.controller.key_down_pressed) { 
					array_push(possible_directions, directions.down);  
		}
		else if current_dir == directions.left &&
				global.controller.key_left && 
				!global.controller.key_right &&
				(global.controller.key_left_pressed || !global.controller.key_left_released) &&
				(!key_pressed_only || global.controller.key_left_pressed) { 
					array_push(possible_directions, directions.left); 
		}
		else if current_dir == directions.right &&
				global.controller.key_right && 
				!global.controller.key_left &&
				(global.controller.key_right_pressed || !global.controller.key_right_released) && 
				(!key_pressed_only || global.controller.key_right_pressed) { 
					array_push(possible_directions, directions.right); 
		}
	}
	
	if (array_length(possible_directions) == 0) { return noone; }
	return possible_directions[0];
}