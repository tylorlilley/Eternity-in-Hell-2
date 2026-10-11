/// @description Draw
// Draw its torch light behind it, unless the torch is hidden (see Step)
if (torch_light_sprite_index != noone) {
	draw_sprite_ext(torch_light_sprite_index, torch_light_image_index, x, y-4, -image_xscale, image_yscale, image_angle, image_blend, INVERTED_COLORS_ALPHA);
}

// Inherit the parent event
event_inherited();

