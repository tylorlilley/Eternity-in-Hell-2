/// @function move_player(_dir)
/// @description Moves the player one step in a direction, and moves what follows the player with them: their light,
///	carried items (and the lights of carried torches) and outline. A crouching player makes no walking noise. The step
///	is recorded for the echo generator to repeat, and the enemies that react to the player's movement update: spiders
///	look for the player, eyes chase them and bumpers teleport next to them. With directions.stairs the player isn't
///	moved, since a room change has just placed them, and only what follows them catches up.
/// @param {real} _dir The direction to move in (see directions); directions.stairs to move only what follows the
///	player, directions.none to do nothing
function move_player(_dir) {
	var _player = global.player, _game_manager = global.game_manager;
	if (_dir == directions.none) { return; }
	
	with (_player) {
		// Step in the direction, silently when crouching, and record the step for the echo generator to repeat
		if (_dir != directions.stairs) {
			move_in_direction(_dir, (sprite_index != spr_player_no_hands_crouch));
			with (obj_echo_generator) { array_push(moves, _dir); }
		}
		// Move light source
		set_instance_to_same_position(light);
		
		// Move carried items and the lights of carried torches
		if (is_existing_instance(right_hand_item)) {
			set_instance_to_same_position(right_hand_item);
			if (is_carrying_item_in_right_hand(obj_torch)) { set_instance_to_same_position(right_hand_item.light_source); }
		}
		if (is_existing_instance(left_hand_item)) {
			set_instance_to_same_position(left_hand_item);
			if (is_carrying_item_in_left_hand(obj_torch)) { set_instance_to_same_position(left_hand_item.light_source); }
		}
		
		// Move outline
		if (is_existing_instance(outline)) { set_instance_to_same_position(outline); }
	}
	
	// Whether a direction key went down this frame, rather than being held from an earlier one
	var _direction_pressed = (_game_manager.key_up_pressed || 
							_game_manager.key_down_pressed || 
							_game_manager.key_right_pressed || 
							_game_manager.key_left_pressed);
	
	// Let spiders check whether they can now see the player
	with (obj_spider) { try_to_see_player(); }
	
	// While no meat is dropped, activated eyes chase the player whenever a direction key is pressed or held, showing their
	// third frame and taking 2 steps along a path to the player. Every eye then turns to face the player
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
				
	// Bumpers teleport near the player (or dropped meat) and turn to face it whenever a direction key is pressed
	if (_direction_pressed) {
		with (obj_bumper_old) {
			teleport_near_player();
			turn_to_face_player();
		}
	}
}

/// @function pick_up_or_put_down_item(_dir)
/// @description Toggles one hand of the player: puts down the item it holds or, when it is empty, picks up an item
///	lying on the player's spot. If there is no item, it takes the head off a corpse on the spot as a piece of meat.
///	Putting down the last torch means the player no longer earns the "Kept the Fire Burning" evaluation. Must be called
///	by the player, since it reads the player's hands and position.
/// @param {real} _dir The hand to toggle, as a direction (see directions): directions.right or directions.left
/// @returns {Id.Instance|undefined} The item picked up, or the meat made from a corpse's head; undefined if an item was
///	put down or there was nothing to pick up
function pick_up_or_put_down_item(_dir) {
	var _carried_item = noone
	if (_dir == directions.right) { _carried_item = right_hand_item; }
	else if (_dir == directions.left) { _carried_item = left_hand_item; }
	
	if (is_existing_instance(_carried_item)) {
		put_down_item(_carried_item, true, true);
		// With no torch left in either hand, the player no longer earns the "Kept the Fire Burning" evaluation
		if (!is_carrying_item(obj_torch)) { global.controller.evaluation_manager.kept_fire = false; }
	}
	else {
		// Find the items under the player and sort them so that the one dropped longest ago comes last, which is the one
		// picked up first. That makes repeated pick-ups cycle through a pile of items
		var _dropped_items = instance_place_all(x, y, obj_item);
		
		array_sort(_dropped_items, function(_elem1, _elem2)
		{
			return -date_compare_datetime(_elem1.last_held, _elem2.last_held);
		});
		
		// Take the first item that nobody holds, that can be picked up, and that is exactly on the player's spot
		while (array_length(_dropped_items) > 0) {
			var _dropped_item = array_pop(_dropped_items);
			if (is_existing_instance(_dropped_item) && !is_existing_instance(_dropped_item.holder) && _dropped_item.can_pick_up && is_instance_at_coordinates(x, y, _dropped_item)) {
				pick_up_item(_dropped_item, true, _dir);
				return _dropped_item;
			}
		}
		
		// With no item to pick up, take the head of a corpse on the spot as meat. Each corpse has only one head
		var _corpses = instance_place_all(x, y, obj_player_corpse);
		while (array_length(_corpses) > 0) {
			var _corpse = array_random_pop(_corpses);
			if (is_existing_instance(_corpse) && is_instance_at_coordinates(x, y, _corpse) && !_corpse.headless) {
				var _new_item = create_item_in_hand(_dir, obj_meat);
				_corpse.headless = true;
				global.controller.evaluation_manager.increment_evaluation_variable("decapitated_corpses");
				play_sound(snd_crunch, true);		
				return _new_item;
			}
		}
	}
}

/// @function pick_up_item(_item, _make_noise, _dir)
/// @description Puts an item into a hand of the calling instance (the player or a hands enemy), facing the side of that
///	hand, and starts the item being carried. The first time an item of that object is picked up in the game, it also
///	counts toward the evaluation's used item types. The hand is expected to be empty.
/// @param {Id.Instance} _item The item to pick up
/// @param {bool} _make_noise Whether to play the pick-up sound
/// @param {real} _dir The hand to pick it up with, as a direction (see directions): directions.right or directions.left
function pick_up_item(_item, _make_noise, _dir) {
	if (_make_noise) { play_sound(snd_pickup, true); }
	
	if (_dir == directions.right) { right_hand_item = _item; _item.image_xscale = -1; }
	else if (_dir == directions.left) { left_hand_item = _item; _item.image_xscale = 1; }
	
	var _used_item_types = global.controller.used_item_types;
	if (!array_contains(_used_item_types, _item.object_index)) {
		array_push(_used_item_types, _item.object_index);
		global.controller.evaluation_manager.increment_evaluation_variable("used_item_types");
	}
	
	with (_item) { become_carried(other.id); }
}

/// @function put_down_item(_item, _make_noise, _dropped)
/// @description Takes an item out of the hand of the calling instance (the player or a hands enemy) that holds it,
///	leaving the item on the ground at the calling instance's position when it is dropped
/// @param {Id.Instance} _item The item to put down
/// @param {bool} _make_noise Whether to play the put-down sound
/// @param {bool} _dropped Whether the item is dropped onto the ground, rather than destroyed, in which case it is only
///	taken out of the hand
function put_down_item(_item, _make_noise, _dropped) {
	if (_make_noise) { play_sound(snd_putdown, true); }
	
	if (right_hand_item == _item) { right_hand_item = noone; }
	else if (left_hand_item == _item) { left_hand_item = noone; }
	
	if (_dropped) { with _item { become_dropped(other.id); } }
}

/// @function get_carried_item(_obj_index)
/// @description The item of a given object that the calling instance (the player or a hands enemy) carries in one of
///	its hands. When both hands carry one, the left hand's is returned if it is special, and the right hand's otherwise.
/// @param {Asset.GMObject} _obj_index The object of the item to look for, such as obj_torch
/// @returns {Id.Instance} The item, or noone if no hand carries one
function get_carried_item(_obj_index) {
	var _carried_item = noone;
	if (is_carrying_item_in_right_hand(_obj_index)) { _carried_item = right_hand_item; }
	if (is_carrying_item_in_left_hand(_obj_index) && (!is_existing_instance(_carried_item) || left_hand_item.special)) { _carried_item = left_hand_item; }
	return _carried_item;
}


/// @function get_carried_lit_torch()
/// @description The lit torch that the calling instance (the player or a hands enemy) carries, a torch being lit while
///	it has a light source. When both hands carry a lit torch, the left hand's is returned if it is special or will stay
///	lit longer, and the right hand's otherwise.
/// @returns {Id.Instance} The lit torch, or noone if no lit torch is carried
function get_carried_lit_torch() {
	var _lit_torch = noone;
	
	if (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source)) { _lit_torch = right_hand_item; }
	if (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source)) {
		if (_lit_torch == noone) { _lit_torch = left_hand_item; }
		else if (left_hand_item.special || _lit_torch.time_to_remain_lit < left_hand_item.time_to_remain_lit) { _lit_torch = left_hand_item; }
	}
	
	return _lit_torch;
}

/// @function is_carrying_item(_obj_index)
/// @description Whether either hand of the calling instance (the player or a hands enemy) carries an item of a given
///	object
/// @param {Asset.GMObject} _obj_index The object of the item to look for, such as obj_torch
/// @returns {bool}
function is_carrying_item(_obj_index) {
	return (is_carrying_item_in_right_hand(_obj_index) || is_carrying_item_in_left_hand(_obj_index));
}

/// @function is_carrying_item_in_right_hand(_obj_index)
/// @description Whether the right hand of the calling instance (the player or a hands enemy) carries an item of a given
///	object
/// @param {Asset.GMObject} _obj_index The object of the item to look for, such as obj_torch
/// @returns {bool}
function is_carrying_item_in_right_hand(_obj_index) {
	return (is_existing_instance(right_hand_item) && right_hand_item.object_index == _obj_index);
}

/// @function is_carrying_item_in_left_hand(_obj_index)
/// @description Whether the left hand of the calling instance (the player or a hands enemy) carries an item of a given
///	object
/// @param {Asset.GMObject} _obj_index The object of the item to look for, such as obj_torch
/// @returns {bool}
function is_carrying_item_in_left_hand(_obj_index) {
	return (is_existing_instance(left_hand_item) && left_hand_item.object_index == _obj_index);
}

/// @function is_carrying_special_item(_obj_index)
/// @description Whether the calling instance (the player or a hands enemy) carries a special item of a given object in
///	either hand
/// @param {Asset.GMObject} _obj_index The object of the item to look for, such as obj_torch
/// @returns {bool}
function is_carrying_special_item(_obj_index) {
	var _item = get_carried_item(_obj_index)
	return (is_existing_instance(_item) && _item.special);
}

/// @function is_carrying_lit_torch(_require_both)
/// @description Whether the calling instance (the player or a hands enemy) carries a lit torch, a torch being lit while
///	it has a light source
/// @param {bool} _require_both Whether both hands must carry a lit torch, rather than either hand
/// @returns {bool}
function is_carrying_lit_torch(_require_both) {
	var _right_hand_lit_torch = false, _left_hand_lit_torch = false;
	
	_right_hand_lit_torch = (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source));
	_left_hand_lit_torch = (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source));
	
	if (_require_both) { return (_right_hand_lit_torch && _left_hand_lit_torch); }
	else { return (_right_hand_lit_torch || _left_hand_lit_torch); }
}

/// @function create_item_in_hand(_dir, _obj_index)
/// @description Creates an item at the player's position, puts it into one of the player's hands, facing the side of
///	that hand, and starts it being carried. The hand is expected to be empty. It always acts on the player, whichever
///	instance calls it.
/// @param {real} _dir The hand to put it in, as a direction (see directions): directions.right or directions.left
/// @param {Asset.GMObject} _obj_index The object of the item to create
/// @returns {Id.Instance} The new item
function create_item_in_hand(_dir, _obj_index) {
	with (global.player) {
		var _new_item = instance_create(x, y, _obj_index)
		
		if (_dir == directions.right) { right_hand_item = _new_item; _new_item.image_xscale = -1; }
		else if (_dir == directions.left) { left_hand_item = _new_item; _new_item.image_xscale =1; }
		
		with (_new_item) { become_carried(other.id); }
		return _new_item;
	}
}

/// @function kill_player(_killed_by_obj)
/// @description Kills the player, unless the game is in a blackout or a room transition. The player is marked dead, the
///	respawn timer starts, the death is counted and logged, the echoes are removed, and everything the player carries is
///	put down except a rosary, which stays in their hand. A player who dies infected by a red bug with time left on the
///	clock is recorded as killed by the bug (obj_bug) instead. Nothing more happens if the player is already dead.
/// @param {Asset.GMObject|real} _killed_by_obj The object that killed the player, or -1 for the object of `other`, the
///	instance that called this from a `with` block on the player
/// @returns {bool} False if a blackout or a room transition stopped the kill, and true otherwise, even when the player
///	was already dead
function kill_player(_killed_by_obj) {
	var _player = global.player, _controller = global.controller;
	// The player can't die during a blackout or a room transition
	if (global.controller.blackout || global.controller.transition != directions.none) { return false; }
	
	if (!_player.dead) {
		// Mark the player dead, start the respawn timer, count the death and remove the echoes by destroying their generator
		_player.depth = CORPSE_DEPTH;
		_player.dead = true;
		_controller.death_timer = RESPAWN_FREQUENCY;
		_controller.evaluation_manager.increment_evaluation_variable("death_count");
		play_sound(snd_lose, true);
		with (obj_echo_generator) { instance_destroy(); }
		
		// Put down everything carried except a rosary, which stays in hand, and note whether the player had one
		var _has_rosary = false;
		with (_player) {
			if (is_existing_instance(right_hand_item) && right_hand_item.object_index != obj_rosary) { put_down_item(right_hand_item, false, true); }
			else if (is_existing_instance(right_hand_item) && right_hand_item.object_index == obj_rosary) { _has_rosary = true; }
			if (is_existing_instance(left_hand_item) && left_hand_item.object_index != obj_rosary) { put_down_item(left_hand_item, false, true); }
			else if (is_existing_instance(left_hand_item) && left_hand_item.object_index == obj_rosary) { _has_rosary = true; }
		}
		
		// Record the cause of death, blaming a red bug instead if the player was infected and still had time left
		_controller.killed_by = (_killed_by_obj == -1) ? other.object_index : _killed_by_obj;
		if (_player.infected_timer > 0 && _controller.time_remaining > 0) { _controller.killed_by = obj_bug; }
		update_death_log(_controller.killed_by, global.difficulty, _has_rosary);
	}
	return true;
}

/// @function can_drop_item(_item)
/// @description Whether the calling instance (the player) can put down the item in a hand where it stands. A shovel
///	needs a spot where a hole can be dug, any other item needs a spot with nothing solid on it, and nothing can be put
///	down outside the room. A hand with no item always passes, so the player can still pick something up.
/// @param {Id.Instance} _item The item in the hand, or noone if the hand is empty
/// @returns {bool}
function can_drop_item(_item) {
	if (!is_existing_instance(_item)) { return true; }
	if (is_outside_room(x, y)) { return false; }
	if (_item.object_index == obj_shovel) { return can_dig_hole(); }
	else { return (!place_meeting(x, y, obj_solid)); }
}

/// @function draw_staff_box()
/// @description Draws the calling instance's own sprite when it carries a staff (the player or a hands enemy), ahead of
///	the inherited Draw event. That event skips an instance that solids or bushes cover, so this keeps a staff carrier
///	visible there.
function draw_staff_box() {
	if (is_carrying_item(obj_staff)) { draw_self(); }
}

/// @function draw_player_hat(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend)
/// @description Draws the farmer hat over the calling instance's sprite, in the farmer graphics mode only, using the
///	crouching hat while the instance crouches. It draws a part of the hat sprite at a position, so that mirror
///	reflections can draw only the part they show. The player, echoes and player corpses draw it.
/// @param {real} _x_pos The x position to draw the sprite part at
/// @param {real} _y_pos The y position to draw the sprite part at
/// @param {real} _x_offset The x position in the sprite where the part to draw starts
/// @param {real} _y_offset The y position in the sprite where the part to draw starts
/// @param {real} _spr_width The width of the part of the sprite to draw
/// @param {real} _spr_height The height of the part of the sprite to draw
/// @param {real} _x_scale The horizontal scale to draw at, negative to mirror the sprite
/// @param {real} _blend The color to blend the sprite with
function draw_player_hat(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend) {
	if (global.graphics_mode == graphics_modes.farmer) {
		var _spr = (sprite_index == spr_player_no_hands_crouch) ? spr_player_farmer_crouch : spr_player_farmer;
		draw_sprite_part_ext(_spr, image_index, _x_offset, _y_offset, _spr_width, _spr_height, _x_pos, _y_pos, _x_scale, image_yscale, _blend, image_alpha);
	}
}

/// @function draw_player_worm(_x_pos, _y_pos, _x_scale, _blend)
/// @description Draws the red bug perched on the player's head while the player is infected and alive. It bobs up and
///	down with the player's walking animation.
/// @param {real} _x_pos The x position to draw at, which is the player's
/// @param {real} _y_pos The y position to draw at, which is the player's; the bug is drawn 10 pixels above it
/// @param {real} _x_scale The horizontal scale to draw at, negative to mirror the sprite
/// @param {real} _blend The color to blend the sprite with
function draw_player_worm(_x_pos, _y_pos, _x_scale, _blend) {
	if (infected_timer > 0 && !dead) { draw_sprite_ext(spr_bug_red, bug_image_index, _x_pos, _y_pos-10+image_index, _x_scale, 1, 0, _blend, 1); }
}

/// @function draw_player_left_hand(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend)
/// @description Draws the left hand sprite over the calling instance's sprite (the player or a player corpse, or their
///	reflection in a mirror). A lost hand is drawn bloody, and an empty hand that is not lost is only drawn in the
///	animation's second frame. When the sprite is mirrored (_x_scale below 0) the left hand sprite stands for the
///	player's right hand, so it follows the right hand's state. It draws a part of the sprite at a position, so that
///	mirror reflections can draw only the part they show. Nothing is drawn when _x_scale is 0.
/// @param {real} _x_pos The x position to draw the sprite part at
/// @param {real} _y_pos The y position to draw the sprite part at
/// @param {real} _x_offset The x position in the sprite where the part to draw starts
/// @param {real} _y_offset The y position in the sprite where the part to draw starts
/// @param {real} _spr_width The width of the part of the sprite to draw
/// @param {real} _spr_height The height of the part of the sprite to draw
/// @param {real} _x_scale The horizontal scale to draw at, negative to mirror the sprite
/// @param {real} _blend The color to blend the sprite with
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

/// @function draw_player_right_hand(_x_pos, _y_pos, _x_offset, _y_offset, _spr_width, _spr_height, _x_scale, _blend)
/// @description Draws the right hand sprite over the calling instance's sprite (the player or a player corpse, or their
///	reflection in a mirror). A lost hand is drawn bloody, and an empty hand that is not lost is only drawn in the
///	animation's second frame. When the sprite is mirrored (_x_scale below 0) the right hand sprite stands for the
///	player's left hand, so it follows the left hand's state. It draws a part of the sprite at a position, so that mirror
///	reflections can draw only the part they show. Nothing is drawn when _x_scale is 0.
/// @param {real} _x_pos The x position to draw the sprite part at
/// @param {real} _y_pos The y position to draw the sprite part at
/// @param {real} _x_offset The x position in the sprite where the part to draw starts
/// @param {real} _y_offset The y position in the sprite where the part to draw starts
/// @param {real} _spr_width The width of the part of the sprite to draw
/// @param {real} _spr_height The height of the part of the sprite to draw
/// @param {real} _x_scale The horizontal scale to draw at, negative to mirror the sprite
/// @param {real} _blend The color to blend the sprite with
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


/// @function draw_player()
/// @description Draws the player: the main sprite, both hands, the farmer hat (in the farmer graphics mode) and the red
///	bug while infected. A player carrying a staff is drawn even where solids or bushes cover them. Called from the
///	player's Draw event when the player is visible.
function draw_player() {
	// Crouching moves the hands and the red bug 1 pixel down, but not the hat
	var _crouch_offset = (sprite_index == spr_player_no_hands_crouch) ? 1 : 0
	// With a staff, draw the player even where solids or bushes cover them
	draw_staff_box();

	// Draw the main sprite with the inherited Draw event
	event_inherited();

	// Draw the hands
	var _x_pos = x-(8*image_xscale), _y_pos = y-(8*image_yscale)+_crouch_offset;
	draw_player_right_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);
	draw_player_left_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

	// Draw the hat, in the farmer graphics mode
	draw_player_hat(_x_pos, _y_pos-_crouch_offset, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

	// Draw the red bug if infected
	draw_player_worm(x, y+_crouch_offset, image_xscale, image_blend);
}

/// @function snap_player_to_position(_dir)
/// @description Puts the player 16 pixels (one tile) behind the calling instance, opposite to the direction the player
///	is pushing it in, and marks the calling instance as what moved the player, so that the player doesn't also move on
///	its own this input frame. Doors and blocks that the player pushes call it, then move the player in the pushed
///	direction.
/// @param {real} _dir The direction the player is pushing the calling instance in (see directions)
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
