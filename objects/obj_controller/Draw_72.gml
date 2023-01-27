shader_set(sh_eih);

shader_set_uniform_f_array(shader_color, global.game_color);

// Draw background
draw_set_color(global.bg_color);
draw_rectangle(0, 0, room_width-1, room_height-1, false);

shader_reset();