/// @function								draw_while_carried();
function draw_while_carried(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _xscale, _blend, _is_mirrored, _spr = sprite_index) {
	if (!is_existing_instance(holder)) { return; }
	
	var _draw_x_offset = image_xscale * -8;
	if (_is_mirrored) { _draw_x_offset *= -1; }
	_y_pos += (holder.sprite_index == spr_player_no_hands_crouch) ? 1 : 0;

	// Draw Main Item Sprite
	draw_sprite_part_ext(_spr, image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos+_draw_x_offset, _y_pos+draw_y_offset, _xscale, image_yscale, _blend, image_alpha);
	
	// Draw Clock Time & Compass Hands
	if (time_sprite_index != noone) {			
		draw_sprite_part_ext(time_sprite_index, time_image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos+_draw_x_offset, _y_pos+draw_y_offset, _xscale, image_yscale, _blend, image_alpha);
	}
	
	// Draw Torch Lights
	if (torch_light_image_timer >= 0) { draw_sprite_part_ext(torch_light_sprite_index, torch_light_image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos+_draw_x_offset, _y_pos+draw_y_offset, _xscale, image_yscale, _blend, image_alpha); }
}

/// @function								become_carried(_new_holder);
/// @param		{boolean} _new_holder		The instance to begin holding the item.
function become_carried(_new_holder) {
	var _controller = global.controller;
	
	// Become carried
	holder = _new_holder;
	persistent = _new_holder.persistent;
	depth = CARRIED_ITEM_DEPTH;
	image_index = 1;
	
	// Update player map
	_controller.current_room.remove_from_instances_at_map_positions(id); 
	
	// Perform individual item pick-up actions
	switch (object_index) {
		case obj_bomb: { defuse_bomb(); break; }
		case obj_shovel: { dig_hole(); break; }
		case obj_heart: { mark_heart_carried(); break; }
		case obj_meat: { array_remove_first(_controller.dropped_meat, id); break; }
		case obj_torch: {
			if (!is_existing_instance(light_source)) {
				var _other_lit_torch = noone;
				if (is_existing_instance(_new_holder)) { 
					with (_new_holder) { _other_lit_torch = get_carried_lit_torch(); }
				}
				if (is_existing_instance(_other_lit_torch) && is_existing_instance(_other_lit_torch.light_source)) { light_torch(_other_lit_torch, true); }
			}
			break;
		}
	}
	
	// Set up Clock and Compass Image Index
	if (sprite_index == get_sprite_to_use(spr_clock) || 
	sprite_index == get_sprite_to_use(spr_clock_farmer) ||
	sprite_index == get_sprite_to_use(spr_compass)) {
		// Update drawn sand and hands for clock and compass sprites
		var _prev_time_image_index = time_image_index;
		if (sprite_index == get_sprite_to_use(spr_compass)) {
			var _new_image_index = get_compass_image_index();
			time_image_index = (_new_image_index == -1) ? time_image_index : _new_image_index;
			time_sprite_index = get_sprite_to_use(spr_compass_hands);
		}
		else {
			time_image_index = get_clock_image_index();
			time_sprite_index = get_sprite_to_use(spr_clock_sand);
		}
	
		if (time_image_index != _prev_time_image_index) {
			play_sound(snd_clock_tick, false);
		}
	}

	// Add evaluation messages
	if (_new_holder == global.player) {
		with (_new_holder) {
			if (is_existing_instance(right_hand_item) && is_existing_instance(left_hand_item) && right_hand_item.object_index == left_hand_item.object_index) {
				increment_run_stat("dual_wielded_items");
				if (right_hand_item.object_index == obj_torch && left_hand_item.object_index == obj_torch && is_existing_instance(right_hand_item.light_source) && is_existing_instance(left_hand_item.light_source)) {
					increment_run_stat("dual_wielded_lit_torches");
				}
			}
		}
	}
}

/// @function								become_dropped(_dropper);
/// @param		{inst} _dropper				The instance dropping this item
function become_dropped(_dropper) {
	var _player = global.player, _controller = global.controller;
	
	// Update player map
	_controller.current_room.add_to_instances_at_map_positions(id); 
	
	// Perform individual item drop actions
	switch (object_index) {
		case obj_meat: {
			if (!array_contains(_controller.dropped_meat, id)) { array_push(_controller.dropped_meat, id); }
			break;
		}
		case obj_shovel: { dropped_by_digger = (_dropper.object_index == obj_player || _dropper.object_index == obj_hands); break; }
		case obj_bomb: {
			if (is_existing_instance(_dropper) && _dropper.object_index == obj_player) {
				var _light_bomb = false;
				with (_dropper) { 
					if (is_carrying_lit_torch(false)) { _light_bomb = true; }
				}
				if (_light_bomb) { light_bomb(); }
			}
			break;
		}
	}
	
	// Become dropped
	last_held = date_current_datetime();
	holder = noone;
	persistent = false;
	depth = DROPPED_ITEM_DEPTH;
	x = _dropper.x;
	y = _dropper.y;
	image_index = 0;
	
	// Perform individual actions based on dropper
	xstart = x;
	ystart = y;
	
	// Alert interested obj_hands to come grab it
	with (obj_hands) { 
		if (_dropper != id && activated && !is_carrying_item(obj_meat) && (!is_existing_instance(right_hand_item) || _dropper == _player || object_is_ancestor(_dropper.object_index, obj_item))) {
			target_item = other.id;
			target_x = target_item.x;
			target_y = target_item.y;
			if (set_automatic_target_path()) { 
				play_sound(snd_laugh, true);
			}
		} 
	}
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	if (object_index == obj_torch) { lighting_range = TORCH_LIGHT_RANGE*2; }
}

/// @function								get_special_draw_alpha();
/// @description							Returns the alpha to draw this item with; INVERTED_COLORS_ALPHA makes the shader swap white and red
function get_special_draw_alpha() {
	if (object_index == obj_lantern) { return 1; } // Lanterns are special so they never burn out, but are not recolored

	var _swap_colors = (object_index == obj_heart) ? !special : special; // Regular hearts are red, special (pure) hearts are white
	return (_swap_colors) ? INVERTED_COLORS_ALPHA : 1;
}

/// @function								defuse_bomb();
function defuse_bomb() {
	if (fuse_timer != 0) { play_sound(snd_fuse, false); }
	fuse_timer = 0;
	visible = true;
}

/// @function					can_dig_hole()
function can_dig_hole() {
	return (!place_meeting(x, y, obj_bones) &&
			!place_meeting(x, y, obj_solid) &&
			!place_meeting(x, y, obj_door) &&
			!place_meeting(x, y, obj_stairs) &&
			!place_meeting(x, y, obj_lava) &&
			!place_meeting(x, y, obj_lantern) &&
			!place_meeting(x, y, obj_cross) &&
			!place_meeting(x, y, obj_bush) &&
			!place_meeting(x, y, obj_block_spot));
}

/// @function								dig_hole();
function dig_hole() {
	if (can_dig_hole() && dropped_by_digger) {
		play_sound(snd_shovel, true);
		if (!special) { damaged += 1; }
		instance_create(x, y, obj_hole);
		increment_run_stat("holes_dug");
	}
}

/// @function								thump();
function thump() {
	if (is_thump_frame()) {
		if (image_index < 2) { play_sound(snd_thump, false); image_index += 2; }
	}
	else if (image_index >= 2) { image_index -= 2; }
}

/// @function								mark_heart_carried();
function mark_heart_carried() {
	var _controller = global.controller;
	if (!_controller.carried_heart && holder == global.player) { 
		_controller.completion_amount += 1;
		_controller.carried_heart = true;
	}
}

/// @function								get_dropped_meat();
function get_dropped_meat() {
	var _dropped_meats = global.controller.dropped_meat;
	if (array_length(_dropped_meats) == 0) { return noone; }
	else { return _dropped_meats[array_length(_dropped_meats)-1]; }
}

/// @function								get_random_item_obj(_special_item, _include_key);
/// @param		{bool} _special_item			Whether to check against the spawned special items or not
/// @param		{bool} _include_key			Whether to include the key in what can be returned or not
function get_random_item_obj(_special_item, _include_key) {
	/*
	var controller = global.controller, difficulty = global.difficulty;
	var available_item_objs = (difficulty == difficulties.easy) ? 2 : 5;
	if (difficulty > difficulties.medium) { available_item_objs += 3; }
	if (include_key) { available_item_objs += 1; }
	var chosen_item_obj = -1;
	*/
	
	var _controller = global.controller, _available_items = global.available_items[global.difficulty], _num_of_items = array_length(_available_items);
	var _random_pos = _include_key ? irandom(_num_of_items-1) : (1 + irandom(_num_of_items-2));
	var _total_spawned_special_items = array_length(_controller.spawned_special_items);
	if (!_include_key) { _total_spawned_special_items += 1; }
	var _chosen_item_obj = noone;
	
	if (_special_item && _total_spawned_special_items >= _num_of_items) {
		write_debug_message("Tried to spawn a special item and failed.", debug_message_level.warning);
		return obj_torch;
	}
	
	// Decide which item to spawn based on previous item spawns
	while (_chosen_item_obj == noone) {
		_chosen_item_obj = _available_items[_random_pos];
		var _spawned_item_count = array_count_occurrences(_controller.spawned_items, _chosen_item_obj);
		var _special_item_count = array_count_occurrences(_controller.spawned_special_items, _chosen_item_obj)
		
		if (global.player_left_hand_item == _chosen_item_obj) { _spawned_item_count += 1; }
		if (global.player_right_hand_item == _chosen_item_obj) { _spawned_item_count += 1; }
			
		// Choose a different item if too many have already spawned
		if (_special_item && _special_item_count > 0) ||
			!_special_item && (
				(_chosen_item_obj == obj_map && _spawned_item_count > 0) ||
				(_chosen_item_obj == obj_compass && _spawned_item_count > 0) ||
				(_chosen_item_obj == obj_staff && _spawned_item_count > 0) ||
				(_chosen_item_obj == obj_clock && _spawned_item_count > 0) ||
				(_chosen_item_obj == obj_shovel && _spawned_item_count > 1) ||
				(_chosen_item_obj == obj_torch && _spawned_item_count > 1)
			) { 
				_random_pos += 1;
				if (_random_pos >= _num_of_items) { _random_pos = 0; }
				if (_random_pos == 0 && !_include_key) { _random_pos += 1; }
				_chosen_item_obj = noone;
		}
		
		/*
		var rand = irandom(available_item_objs);
		if (!include_key) { rand += 1; }

		switch (rand) {
			case 0: { chosen_item_obj = obj_key; break; }
			case 1: { chosen_item_obj = obj_torch; break; }
			case 2: { chosen_item_obj = obj_sword; break; }
			case 3: { chosen_item_obj = obj_map; break; }
			case 4: { chosen_item_obj = obj_rosary; break; }
			case 5: { chosen_item_obj = obj_staff; break; }
			case 6: { chosen_item_obj = obj_bomb; break; }
			case 7: { chosen_item_obj = obj_meat; break; }
			case 8: { chosen_item_obj = obj_shovel; break; }
			case 9: { chosen_item_obj = obj_clock; break; }
		}
		
		var special_item_count = array_count_occurrences(controller.spawned_special_items, chosen_item_obj)
			
		if (special_item_count >= 1) { chosen_item_obj = -1; }
		else if (!special_item) {
			var spawned_item_count = array_count_occurrences(controller.spawned_items, chosen_item_obj);
			if (chosen_item_obj == obj_map && spawned_item_count >= 1) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_staff && spawned_item_count >= 1) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_clock && spawned_item_count >= 2) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_shovel && spawned_item_count >= 2) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_torch && spawned_item_count >= 2 && array_length(controller.spawned_special_items) == 0) { chosen_item_obj = -1; }
		}
		*/
	}
	
	return _chosen_item_obj;
}


/// @function								get_clock_image_index();
function get_clock_image_index() {
	var _controller = global.controller;
	var _time_elapsed = _controller.time_provided - _controller.time_remaining;
	var _time_per_grain = (_time_elapsed / _controller.time_provided)
	var _sand_image_index = floor(abs((_time_per_grain*8) - (_time_per_grain*3/4)));

	return _sand_image_index;
}

/// @function								get_compass_image_index();
function get_compass_image_index() {
	var _controller = global.controller, _player = global.player, _hands_dir = 90;
	
	if (_controller.current_room.has_hall_of_mirrors) {
		// Point towards Next Hall of Mirrors Exit
		var _next_dir = _controller.current_room.mirror_directions[_controller.current_room.mirror_count];
		var _x_pos = x, _y_pos = y;
		switch (_next_dir) {
			case directions.up: { _y_pos -= 2; break; }
			case directions.right: { _x_pos += 2; break; }
			case directions.down: { _y_pos += 2; break; }
			case directions.left: { _x_pos -= 2; break; }
		}
		_hands_dir = point_direction(x, y, _x_pos, _y_pos);
	}
	else if (instance_number(obj_collectable) > 0) {
		// Point towards Nearest Collectable in Room
		var _nearest_collectable = instance_nearest(x, y, obj_collectable);
		_hands_dir = point_direction(x, y, _nearest_collectable.x, _nearest_collectable.y);
		if (is_instance_at_coordinates(_player.x, _player.y, _nearest_collectable)) { return -1; }
	}
	else {
		var _current_room_x = _controller.current_room.virtual_x, _current_room_y = _controller.current_room.virtual_y;
		var _target_room_x = _current_room_x, _target_room_y = _current_room_y-1; // Default to pointing up
		
		// Point towards start room if heart is collected
		if (_controller.completion_amount+1 >= TOTAL_COMPLETION_AMOUNT) {
			 if (instance_number(obj_cross) > 0) {
				var _nearest_cross = instance_nearest(x, y, obj_cross);
				_hands_dir = point_direction(x, y, _nearest_cross.x, _nearest_cross.y);
				if (is_instance_at_coordinates(_player.x, _player.y, _nearest_cross)) { return -1; }
			}
			else {
				 _target_room_x = _controller.start_room.virtual_x;
				 _target_room_y = _controller.start_room.virtual_y;
				 _hands_dir = point_direction(_current_room_x, _current_room_y, _target_room_x, _target_room_y);
			}
		}
		// Point towards heart room if all collectables are collected
		else if (are_all_collectables_collected()) {
			if (instance_number(obj_encased_heart) > 0) {
				var _nearest_heart = instance_nearest(x, y, obj_encased_heart);
				_hands_dir = point_direction(x, y, _nearest_heart.x, _nearest_heart.y);
				if (is_instance_at_coordinates(_player.x, _player.y, _nearest_heart)) { return -1; }
			}
			else if (instance_number(obj_heart) > 0) {
				var _nearest_heart = instance_nearest(x, y, obj_heart);
				_hands_dir = point_direction(x, y, _nearest_heart.x, _nearest_heart.y);
				if (is_instance_at_coordinates(_player.x, _player.y, _nearest_heart)) { return -1; }
			}
			else {
				_target_room_x = _controller.heart_room.virtual_x;
				_target_room_y = _controller.heart_room.virtual_y;
				_hands_dir = point_direction(_current_room_x, _current_room_y, _target_room_x, _target_room_y);
			}
		}
		// Point towards nearest room with collectables
		else {
			var _smallest_dist = 999, _target_room = self;
			for (var _i = 0; _i < array_length(_controller.rooms_with_collectables); _i++) {
				var _collectables_room = _controller.rooms_with_collectables[_i];
				var _current_dist = abs(point_distance(_current_room_x, _current_room_y, _collectables_room.virtual_x, _collectables_room.virtual_y));			
				if (_current_dist < _smallest_dist) {
					_smallest_dist = _current_dist;
					_target_room = _collectables_room;
				}
			}
			_target_room_x = _target_room.virtual_x;
			_target_room_y = _target_room.virtual_y;
			_hands_dir = point_direction(_current_room_x, _current_room_y, _target_room_x, _target_room_y);
		}
	}
	
	// Translate from GML dir to image_index value
	_hands_dir = 360 - _hands_dir;
	_hands_dir += 90;
	if (_hands_dir >= 360) { _hands_dir -= 360; }
	var _hands_image_index = round(_hands_dir / 45);
	if (image_xscale == -1) { _hands_image_index += (4-_hands_image_index)*2; }
	if (_hands_image_index >= 8) { _hands_image_index -= 8; }
	return _hands_image_index;
}

/// @function								light_bomb();
function light_bomb() {
	if (fuse_timer != 0) { return false; }
	if (lit_by_player) { 
		increment_run_stat("bombs_lit");
	}
	play_sound(snd_torchlight, true);
	fuse_timer = 4*irandom_range(5,8);
	return true;
}


/// @function								get_carried_item_draw_y_offset(special_item, include_key);
/// @param		{spr} _spr_index				The sprite index to get the carried y offset for
function get_carried_item_draw_y_offset(_spr_index) {
	var _y_offset = -2;
	
	switch (_spr_index) {
		case spr_rosary:
			{ _y_offset = 2; break; }
		case spr_staff: 
			{ _y_offset = 0; break; }
		case spr_meat:
		case spr_meat_farmer:
			{ _y_offset = 0; break; }
		case spr_compass: 
			{ _y_offset = -3; break; }
		case spr_shovel:
			{ _y_offset = -3; break; }
		case spr_torch: 
			{ _y_offset = -4; break; }
		case spr_sword: 
		case spr_sword_farmer:
			{ _y_offset = -6; break; }
	}
	
	return _y_offset;
}