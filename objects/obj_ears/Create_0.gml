event_inherited();
set_farm_mode_sprite(spr_ears_farmer);

image_speed = one_unit_of_game_time();;
image_xscale = (get_random_chance_out_of(2)) ? 1 : -1;

corporeal = false;

awake = false;
hiss_timer = -1;
target_x = xstart;
target_y = ystart;