set_eih_shader();

// Draw Borderless Fullscreen Background
draw_set_color(c_black);
draw_rectangle(0, 0, display_get_width(), display_get_height(), false);

// Draw Game Background
draw_set_color(global.bg_color);
draw_rectangle(0, 0, room_width-1, room_height-1, false);
