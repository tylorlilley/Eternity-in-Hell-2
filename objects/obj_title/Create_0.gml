randomize();

depth = -9999;
room_speed = 60;

global.controller = noone;
global.bg_color = make_color_rgb(0, 0, 0);

loading = false;
current_seed = noone;
pos = -2;
prepare_screen = false;
left_hand_selected = true;
hand_options = array_create(0);
options_pos = 0;
color_options_pos = 5;
option_selected = false;
options_screen = false;
controls_screen = false;
death_log_screen = false;
death_log_pos = 0;
death_log_sort = 0;
death_types_on_screen = 7;
deaths_to_display = array_create(0);
evaluation_log_screen = false;
evaluation_log_position = 0;
evaluation_manager = new EvaluationMessageManager();
held_timer = 0;

// Update game graphics textures
draw_texture_flush();
sprite_prefetch(spr_logo);
sprite_prefetch(spr_collectable);
sprite_prefetch(spr_player);
sprite_prefetch(spr_player_farmer);