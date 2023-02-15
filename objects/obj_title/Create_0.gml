randomize();

room_speed = 60;

global.controller = noone;
global.bg_color = make_color_rgb(0, 0, 0);

can_access_farmer_mode = false;
current_seed = noone;
pos = -2;
options_pos = 0;
options_screen = false;
loading = false;
blink_timer = 15;
blink = false;

// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_logo);
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
sprite_prefetch(spr_player_farmer);