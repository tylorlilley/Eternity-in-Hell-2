set_eih_shader();

// Draw background
draw_set_color(global.bg_color);
draw_rectangle(0, 0, room_width-1, room_height-1, false);

// Draw Title
draw_sprite_ext(spr_logo, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1);

shader_reset();
