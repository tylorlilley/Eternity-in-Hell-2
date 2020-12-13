/// @function								draw_while_carried();
function draw_while_carried() {
	var x_offset = 8;
	
	if (global.player.dead) { x_offset += 0; }
	draw_sprite_ext(sprite_index, image_index, x-sprite_width+(image_xscale*x_offset),y-2,image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}
