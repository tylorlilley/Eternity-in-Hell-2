/// @function								move_player(_dir);
/// @param		{direction} _dir				The direction to move the player instance
function move_player(_dir) {
	var _player = global.player, _game_manager = global.game_manager;
	if (_dir == directions.none) { return; }
	
	with (_player) {
		// Move player
		if (_dir != directions.stairs) {
			move_in_direction(_dir, (sprite_index != spr_player_no_hands_crouch));
			with (obj_echo_generator) { array_push(moves, _dir); }
		}
		// Move light source
		set_instance_to_same_position(light);
		
		// Move carried items
		if (is_existing_instance(right_hand_item)) {
			set_instance_to_same_position(right_hand_item);
			if (is_carrying_item_in_right_hand(obj_torch)) { set_instance_to_same_position(right_hand_item.light_source); }
		}
		if (is_existing_instance(left_hand_item)) {
			set_instance_to_same_position(left_hand_item);
			if (is_carrying_item_in_left_hand(obj_torch)) { set_instance_to_same_position(left_hand_item.light_source); }
		}
		
		// Move Outline
		if (is_existing_instance(outline)) { set_instance_to_same_position(outline); }
	}
	
	var _direction_pressed = (_game_manager.key_up_pressed || 
							_game_manager.key_down_pressed || 
							_game_manager.key_right_pressed || 
							_game_manager.key_left_pressed);
	
	// Update the spiders state
	with (obj_spider) { try_to_see_player(); }
	
	// Update the eyes postition
	with (obj_eyes) {
		var _target = get_dropped_meat();
		if (!is_existing_instance(_target)) {
			_target = _player;
			
			if (activated) {
				if (_direction_pressed ||
					_game_manager.key_up || 
					_game_manager.key_down || 
					_game_manager.key_left || 
					_game_manager.key_right) {
						blink_amount = irandom_range(12, 32);
						target_x = _target.x;
						target_y = _target.y;
						set_automatic_target_path();
						move_towards_coordinates_on_path(false, false, 2);
						if (target_path != noone) { play_sound(snd_thud, false); }
						if (image_index != 2 && _direction_pressed) { play_sound(snd_eyes, true); }
						image_index = 2;
				}
			}
		}
		turn_to_face_player();
	}
				
	// Update the bumper position
	if (_direction_pressed) {
		with (obj_bumper_old) {
			teleport_near_player();
			turn_to_face_player();
		}
	}
}

/// @function								pick_up_or_put_down_item(_dir);
/// @param		{direction} _dir				The directional slot to pick up or drop an item into or from
function pick_up_or_put_down_item(_dir) {
	var _carried_item = noone
	if (_dir == directions.right) { _carried_item = right_hand_item; }
	else if (_dir == directions.left) { _carried_item = left_hand_item; }
	
	if (is_existing_instance(_carried_item)) {
		var _is_putting_down_torch = (_carried_item.object_index == obj_torch);
		put_down_item(_carried_item, true, true);
		if (_is_putting_down_torch && !is_carrying_item(obj_torch)) { increment_run_stat("carried_torch_lost_count"); }
	}
	else {
		// Cycle through the items you could be possibly picking up
		var _dropped_items = instance_place_all(x, y, obj_item);
		
		array_sort(_dropped_items, function(_elem1, _elem2)
		{
			return -date_compare_datetime(_elem1.last_held, _elem2.last_held);
		});
		
		while (array_length(_dropped_items) > 0) {
			var _dropped_item = array_pop(_dropped_items);
			if (is_existing_instance(_dropped_item) && !is_existing_instance(_dropped_item.holder) && _dropped_item.can_pick_up && is_instance_at_coordinates(x, y, _dropped_item)) {
				pick_up_item(_dropped_item, true, _dir);
				return _dropped_item;
			}
		}
		
		var _corpses = instance_place_all(x, y, obj_player_corpse);
		while (array_length(_corpses) > 0) {
			var _corpse = array_random_pop(_corpses);
			if (is_existing_instance(_corpse) && is_instance_at_coordinates(x, y, _corpse) && !_corpse.headless) {
				var _new_item = create_item_in_hand(_dir, obj_meat);
				_corpse.headless = true;
				increment_run_stat("decapitated_corpses");
				play_sound(snd_crunch, true);		
				return _new_item;
			}
		}
	}
}

/// @function								pick_up_item(_item, _make_noise, _dir);
/// @param		{instance} _item				The item to pick up
/// @param		{boolean} _make_noise		Whether or not to make a noise as part of picking up the item.
/// @param		{direction} _dir				The hand this item is being picked up with
function pick_up_item(_item, _make_noise, _dir) {
	if (_make_noise) { play_sound(snd_pickup, true); }
	
	if (_dir == directions.right) { right_hand_item = _item; _item.image_xscale = -1; }
	else if (_dir == directions.left) { left_hand_item = _item; _item.image_xscale = 1; }
	
	var _used_item_types = global.controller.used_item_types;
	if (!array_contains(_used_item_types, _item.object_index)) {
		array_push(_used_item_types, _item.object_index);
		increment_run_stat("used_item_types");
	}
	
	with (_item) { become_carried(other.id); }
}

/// @function								put_down_item(_item, _make_noise, _dropped);
/// @param		{instance} _item				The item to pick up
/// @param		{boolean} _make_noise		Whether or not to make a noise as part of putting down the item.
/// @param		{boolean} _dropped			Whether or not this item is being dropped and not destroyed
function put_down_item(_item, _make_noise, _dropped) {
	if (_make_noise) { play_sound(snd_putdown, true); }
	
	if (right_hand_item == _item) { right_hand_item = noone; }
	else if (left_hand_item == _item) { left_hand_item = noone; }
	
	if (_dropped) { with _item { become_dropped(other.id); } }
}

/// @function								get_carried_item(dir);
/// @param		{index} _obj_index			The object type to check the carried items for
function get_carried_item(_obj_index) {
	var _carried_item = noone;
	if (is_carrying_item_in_right_hand(_obj_index)) { _carried_item = right_hand_item; }
	if (is_carrying_item_in_left_hand(_obj_index) && (!is_existing_instance(_carried_item) || left_hand_item.special)) { _carried_item = left_hand_item; }
	return _carried_item;
}


/// @function								get_carried_lit_torch();
function get_carried_lit_torch() {
	var _lit_torch = noone;
	
	if (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source)) { _lit_torch = right_hand_item; }
	if (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source)) {
		if (_lit_torch == noone) { _lit_torch = left_hand_item; }
		else if (left_hand_item.special || _lit_torch.time_to_remain_lit < left_hand_item.time_to_remain_lit) { _lit_torch = left_hand_item; }
	}
	
	return _lit_torch;
}

/// @function								is_carrying_item(_obj_index);
/// @param		{index} _obj_index			The object type to check the carried items for
function is_carrying_item(_obj_index) {
	return (is_carrying_item_in_right_hand(_obj_index) || is_carrying_item_in_left_hand(_obj_index));
}

/// @function								is_carrying_item_in_right_hand(_obj_index);
/// @param		{index} _obj_index			The object type to check the carried items for
function is_carrying_item_in_right_hand(_obj_index) {
	return (is_existing_instance(right_hand_item) && right_hand_item.object_index == _obj_index);
}

/// @function								is_carrying_item_in_left_hand(_obj_index);
/// @param		{index} _obj_index			The object type to check the carried items for
function is_carrying_item_in_left_hand(_obj_index) {
	return (is_existing_instance(left_hand_item) && left_hand_item.object_index == _obj_index);
}

/// @function								is_carrying_special_item(dir);
/// @param		{index} _obj_index			The object type to check the carried items for
function is_carrying_special_item(_obj_index) {
	var _item = get_carried_item(_obj_index)
	return (is_existing_instance(_item) && _item.special);
}

/// @function								is_carrying_lit_torch(_require_both);
/// @param		{bool} _require_both			Whether to require a lit torch in both hands or not
function is_carrying_lit_torch(_require_both) {
	var _right_hand_lit_torch = false, _left_hand_lit_torch = false;
	
	_right_hand_lit_torch = (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source));
	_left_hand_lit_torch = (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source));
	
	if (_require_both) { return (_right_hand_lit_torch && _left_hand_lit_torch); }
	else { return (_right_hand_lit_torch || _left_hand_lit_torch); }
}

/// @function								create_item_in_hand(_dir, _obj_index);
/// @param		{direction} _dir				The directional slot to pick up or drop an item into or from
/// @param		{index} _obj_index			The type of item to create in hand
function create_item_in_hand(_dir, _obj_index) {
	with (global.player) {
		var _new_item = instance_create(x, y, _obj_index)
		
		if (_dir == directions.right) { right_hand_item = _new_item; _new_item.image_xscale = -1; }
		else if (_dir == directions.left) { left_hand_item = _new_item; _new_item.image_xscale =1; }
		
		with (_new_item) { become_carried(other.id); }
		return _new_item;
	}
}

/// @function								kill_player(_killed_by_obj);
/// @param		{obj} _killed_by_obj				The object_index of the thing killing the player
function kill_player(_killed_by_obj) {
	var _player = global.player, _controller = global.controller;
	if (global.controller.blackout || global.controller.transition != directions.none) { return false; }
	
	if (!_player.dead) {
		// Set variables to mark death
		_player.depth = CORPSE_DEPTH;
		_player.dead = true;
		_controller.death_timer = RESPAWN_FREQUENCY;
		play_sound(snd_lose, true);
		with (obj_echo_generator) { instance_destroy(); }
		
		// Put down carried items other than rosary, which loses a carried torch's fire
		with (_player) {
			if (is_carrying_item(obj_torch)) { increment_run_stat("carried_torch_lost_count"); }
			if (is_existing_instance(right_hand_item) && right_hand_item.object_index != obj_rosary) { put_down_item(right_hand_item, false, true); }
			if (is_existing_instance(left_hand_item) && left_hand_item.object_index != obj_rosary) { put_down_item(left_hand_item, false, true); }
		}
		
		_controller.killed_by = (_killed_by_obj == -1) ? other.object_index : _killed_by_obj;
		if (_player.infected_timer > 0 && _controller.time_remaining > 0) { _controller.killed_by = obj_bug; }
		record_run_death(_controller.killed_by);
	}
	return true;
}

/// @function					can_drop_item(_item)
/// @param		{inst} _item		The item you are trying to drop
function can_drop_item(_item) {
	if (!is_existing_instance(_item)) { return true; }
	if (is_outside_room(x, y)) { return false; }
	if (_item.object_index == obj_shovel) { return can_dig_hole(); }
	else { return (!place_meeting(x, y, obj_solid)); }
}

/// @function				draw_staff_box();
function draw_staff_box() {
	if (is_carrying_item(obj_staff)) { draw_self(); }
}

/// @function				draw_player_hat();
function draw_player_hat(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend) {
	if (global.graphics_mode == graphics_modes.farmer) {
		var _spr = (sprite_index == spr_player_no_hands_crouch) ? spr_player_farmer_crouch : spr_player_farmer;
		draw_sprite_part_ext(_spr, image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos, _y_pos, _x_scale, image_yscale, _blend, image_alpha);
	}
}

/// @function				draw_player_worm();
function draw_player_worm(_x_pos, _y_pos, _x_scale, _blend) {
	if (infected_timer > 0 && !dead) { draw_sprite_ext(spr_bug_red, bug_image_index, _x_pos, _y_pos-10+image_index, _x_scale, 1, 0, _blend, 1); }
}

/// @function				draw_player_left_hand();
function draw_player_left_hand(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend) {
	if (_x_scale == 0) { return; }
	else if (_x_scale > 0) {
		var _left_hand_sprite = (lost_left_hand) ? get_sprite_to_use(spr_player_bloody_left_hand) : spr_player_left_hand;
		var _hide_left_hand = (image_index == 0 && !lost_left_hand && !is_existing_instance(left_hand_item));
	}
	else {
		var _left_hand_sprite = (lost_right_hand) ? get_sprite_to_use(spr_player_bloody_left_hand) : spr_player_left_hand;
		var _hide_left_hand = (image_index == 0 && !lost_right_hand && !is_existing_instance(right_hand_item));
	}
	if (!_hide_left_hand) { draw_sprite_part_ext(_left_hand_sprite, image_index, _x_offset, _y_offset, _spr_width, _spr_height,  _x_pos, _y_pos, _x_scale, image_yscale, _blend, image_alpha); }
}

/// @function				draw_player_right_hand();
function draw_player_right_hand(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend) {
	if (_x_scale == 0) { return; }
	else if (_x_scale > 0) {
		var _right_hand_sprite = (lost_right_hand) ? get_sprite_to_use(spr_player_bloody_right_hand) : spr_player_right_hand;
		var _hide_right_hand = (image_index == 0 && !lost_right_hand && !is_existing_instance(right_hand_item));
	}
	else if (_x_scale < 0) {
		var _right_hand_sprite = (lost_left_hand) ? get_sprite_to_use(spr_player_bloody_right_hand) : spr_player_right_hand;
		var _hide_right_hand = (image_index == 0 && !lost_left_hand && !is_existing_instance(left_hand_item));
	}
	if (!_hide_right_hand) { draw_sprite_part_ext(_right_hand_sprite, image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos, _y_pos, _x_scale, image_yscale, _blend, image_alpha); }
}


/// @function						draw_player();
function draw_player() {
	var _crouch_offset = (sprite_index == spr_player_no_hands_crouch) ? 1 : 0
	// Draw box over lava or staff solids
	draw_staff_box();

	// Draw main sprite
	event_inherited();

	// Draw Hands
	var _x_pos = x-(8*image_xscale), _y_pos = y-(8*image_yscale)+_crouch_offset;
	draw_player_right_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);
	draw_player_left_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

	// Draw hat in farm mode
	draw_player_hat(_x_pos, _y_pos-_crouch_offset, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

	// Draw worm if infected
	draw_player_worm(x, y+_crouch_offset, image_xscale, image_blend);
}

/// @function				snap_player_to_position(_dir);
/// @param		{dir} _dir	The direction to snap the player opposite to
function snap_player_to_position(_dir) {
	var _player = global.player;
	_player.moved_by = id;
	_player.x = x;
	_player.y = y;
	switch (_dir) {
		case directions.up: { _player.y += 16; break; }
		case directions.down: { _player.y -= 16; break; }
		case directions.left: { _player.x += 16; break; }
		case directions.right: { _player.x -= 16; break; }
	}
}
