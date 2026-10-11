/// @description Draw Mirror and Reflections

// Draw the mirror's glass, where the reflections other objects draw in this event land (see draw_reflection_in_mirrors)
draw_sprite_ext(spr_mirror, 0, x, y, image_xscale, image_yscale, image_angle, image_blend, 1);
