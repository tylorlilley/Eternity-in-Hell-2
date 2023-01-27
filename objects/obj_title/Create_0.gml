randomize();
audio_group_load(audiogroup_default);
room_speed = 60;

global.id_counter = 0;
global.controller = noone;
global.bg_color = make_color_rgb(0, 0, 0);

current_seed = noone;
shader_color = shader_get_uniform(sh_eih, "new_color");
shader_bg_color = shader_get_uniform(sh_eih, "bg_color");

pos = -2;
options_pos = 0;
options_screen = false;
loading = false;
blink_timer = 15;
blink = false;