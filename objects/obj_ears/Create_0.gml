event_inherited();

meat_eater = true;
awake = false;
target_x = x;
target_y = y;
killable_by_sword = true;
consumed_by_block = false;
consumed_by_lava = false;
death_sound = snd_crunch;
hiss_timer = -1;
image_speed = one_unit_of_game_time();;
image_xscale = (get_random_chance_out_of(2)) ? 1 : -1;