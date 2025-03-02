/// @description Draw
if (torch_light_sprite_index != noone) {
	draw_sprite_ext(torch_light_sprite_index, torch_light_image_index, x, y-4, -image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

// Inherit the parent event
event_inherited();

