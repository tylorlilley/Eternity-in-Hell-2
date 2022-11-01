/// @function								draw_while_carried();
/// @param		{real} y_offset				How vertically displaced rom the player's origin should this should be drawn
/// @param		{direction} dir				The hand this item is being held in
function draw_while_carried(y_offset, dir) {
	var x_scale = (dir == directions.left) ? image_xscale : -image_xscale;
	var x_offset = (dir == directions.left) ? 8 : -24;

	draw_sprite_ext(sprite_index, image_index, x-sprite_width+(x_scale*x_offset),y+y_offset, x_scale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function								pick_up_item();
/// @param		{direction} dir				The hand this item is being picked up with
/// @param		{boolean} play_sound		Whether or not the item previously existed as a dropped item.
/// @param		{boolean} holder			The instance to begin holding the item.
function pick_up_item(dir, play_sound, new_holder) {
	if (play_sound) { audio_play_sound(snd_pickup, 10, false); }
	holder = new_holder
	holder.carried_items[dir] = id;
	persistent = holder.persistent;
	image_xscale = holder.image_xscale;
	carried = dir;
	depth = -10;
	if (!has_been_carried) {
		has_been_carried = true;
		if (holder == global.player) {
			if (object_index == obj_key) { global.controller.current_room.has_key = false; }
			else if (object_index == obj_heart) { global.controller.completion_amount += 1; }
		}
	}
}

/// @function								drop_item();
/// @param		{direction} dir				The hand this item is being dropped out of
function drop_item(dir, play_sound) {	
	if (play_sound) { audio_play_sound(snd_putdown, 10, false);}
	if (holder) { 
		holder.carried_items[dir] = noone;
		x = holder.x;
		y = holder.y;
		holder = noone;
	}
	carried = noone;
	persistent = false;
	depth = 2;
	image_xscale = (dir == directions.left) ? image_xscale : -image_xscale;
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	image_index = 1;
	if (object_index == obj_torch) { 
		image_index = 0;
		lighting_range = global.controller.TORCH_LIGHT_RANGE*2;
		sprite_index = spr_special_torch; 
	}
}
