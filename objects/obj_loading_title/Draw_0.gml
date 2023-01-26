// Draw background
draw_set_color(c_black);
draw_rectangle(0, 0, room_width, room_height, false);

// Draw Title
draw_sprite_ext(spr_logo, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1);
