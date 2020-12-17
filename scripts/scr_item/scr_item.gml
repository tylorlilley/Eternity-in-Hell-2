/// @function								draw_while_carried();
/// @param		{real} y_offset				How vertically displaced rom the player's origin should this should be drawn
/// @param		{direction} dir				The hand this item is being held in
function draw_while_carried(y_offset, dir) {
	var x_scale = (dir == directions.left) ? image_xscale : -image_xscale;
	var x_offset = (dir == directions.left) ? 8 : -24;
	
	if (global.player.dead) { x_offset += 0; }
	draw_sprite_ext(sprite_index, image_index, x-sprite_width+(x_scale*x_offset),y+y_offset, x_scale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function								pick_up_item();
/// @param		{direction} dir				The hand this item is being picked up with
/// @param		{boolean} item_existed		Whether or not the item previously existed as a dropped item.
function pick_up_item(dir, item_existed) {
	if (item_existed) { audio_play_sound(snd_pickup, 10, false); }
	global.player.carried_items[dir] = id;
	carried = dir;
	persistent = true;
	depth = -10;
	image_xscale = global.player.image_xscale;
}

/// @function								drop_item();
/// @param		{direction} dir				The hand this item is being dropped out of
function drop_item(dir) {	
	global.player.carried_items[dir] = noone;
	carried = noone;
	persistent = false;
	x = global.player.x;
	y = global.player.y;
	audio_play_sound(snd_pickup, 10, false);
	depth = 2;
	image_xscale = (dir == directions.left) ? image_xscale : -image_xscale;
}