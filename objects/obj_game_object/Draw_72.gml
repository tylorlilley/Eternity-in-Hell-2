shader_set(sh_eih);

shader_set_uniform_f_array(shader_color, global.game_color);
shader_set_uniform_f_array(shader_bg_color, get_shader_color_from_gms_color(global.bg_color));