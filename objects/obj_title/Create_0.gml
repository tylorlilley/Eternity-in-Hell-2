randomize();

depth = -9999;
room_speed = 60;

global.controller = noone;
global.bg_color = make_color_rgb(0, 0, 0);

can_access_farmer_mode = false;
current_seed = noone;
pos = -2;
options_pos = 0;
options_screen = false;
controls_screen = false;
deaths_to_display = array_create(0);
death_log_sort = 0;
death_log_screen = false;
death_log_pos = 0;
loading = false;

// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_logo);
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
sprite_prefetch(spr_player_farmer);