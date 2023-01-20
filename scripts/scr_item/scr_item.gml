/// @function								draw_while_carried();
function draw_while_carried() {
	if (holder == noone) { return; }
	
	var x_offset = (holder.right_hand_item == id) ? 8 : -8;

	draw_sprite_ext(sprite_index, image_index, x+x_offset, y+draw_y_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function								become_carried(new_holder);
/// @param		{boolean} new_holder		The instance to begin holding the item.
function become_carried(new_holder) {
	// Perform individual item pick-up actions
	switch (object_index) {
		case obj_key: { if (holder == global.player) { global.controller.current_room.has_keys -= 1; } break; }
		case obj_bomb: { defuse_bomb(); break; }
		case obj_shovel: { dig_hole(); break; }
		case obj_heart: { mark_heart_carried(); break; }
	}
		
	// Become carried
	holder = new_holder;
	persistent = new_holder.persistent;
	depth = -10;
}

/// @function								become_dropped(dropper);
/// @param		{inst} dropper				The instance dropping this item
function become_dropped(dropper) {
	// Perform individual item drop actions
	switch (object_index) {
		case obj_key: { if (dropper == global.player) { global.controller.current_room.has_keys += 1; } break; }
		case obj_meat: { with (obj_spider) { if (activated) { play_sound(snd_lose, false); } } break; }
	}
	
	// Become dropped
	holder = noone;
	persistent = false;
	depth = 2;
	x = dropper.x;
	y = dropper.y;
	
	// Perform individual actions based on dropper
	if (dropper == global.player) {
		xstart = x;
		ystart = y;
	}
	
	// Alert interested obj_hands to come grab it
	with (obj_hands) { 
		if (dropper != id && activated && !is_carrying_item(obj_meat) && (right_hand_item == noone || dropper == global.player)) { target_item = other.id; } 
	}
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	image_index = 1;
	if (object_index == obj_torch) { 
		image_index = 0;
		lighting_range = global.controller.TORCH_LIGHT_RANGE*2;
		sprite_index = get_sprite_to_use(spr_special_torch); 
	}
}

/// @function								thump();
function thump() {
	thump_timer -= 1;
	if (thump_timer == 3) { play_sound(snd_thump, false); image_index = 1; }
	if (thump_timer == 0) { thump_timer = 12; image_index = 0; }
}

/// @function								get_random_item_type(include_key);
/// @param		{bool} include_key			Whether to include the key in what can be returned or not
function get_random_item_type(include_key) {
	var available_item_types = (global.difficulty == difficulties.easy) ? 2 : 5;
	if (global.difficulty > difficulties.medium) { available_item_types += 3; }
	var rand = irandom(available_item_types);
	if (!include_key) { rand += 1; }

	switch (rand) {
		case 0: { return obj_key; }
		case 1: { return obj_torch; }
		case 2: { return obj_sword; }
		case 3: { return obj_map; }
		case 4: { return obj_rosary; }
		case 5: { return obj_staff; }
		case 6: { return obj_bomb; }
		case 7: { return obj_meat; }
		case 8: { return obj_shovel; }
		case 9: { return obj_clock; }
	}
}

/// @function								defuse_bomb();
function defuse_bomb() {
	if (fuse_timer != 0) { play_sound(snd_hiss, false); }
	fuse_timer = 0; 
}

/// @function								dig_hole();
function dig_hole() {
	if (can_make_hole()) {
		play_sound(snd_shovel, true);
		if (!special) { damaged += 1; }
		var new_hole = instance_create_depth(x, y, 0, obj_hole);
		if (global.controller.last_hole == noone) { global.controller.last_hole = new_hole; }
		else { 
			new_hole.connected_hole = global.controller.last_hole; 
			global.controller.last_hole.connected_hole = new_hole;
			global.controller.last_hole = noone;
		}
	}
}

/// @function								mark_heart_carried();
function mark_heart_carried() {
	if (!global.controller.carried_heart && holder == global.player) { 
		global.controller.completion_amount += 1;
		global.controller.carried_heart = true;
	}
}

/// @function								get_dropped_meat();
function get_dropped_meat() {
	var dropped_meat = noone
	with (obj_meat) { if (holder == noone) { dropped_meat = id; } }
	return dropped_meat;
}
