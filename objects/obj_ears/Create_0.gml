event_inherited();

awake = false;
target_x = x;
target_y = y;
killable_by_sword = true;
consumed_by_block = false;
consumed_by_lava = false;
death_sound = snd_crunch;
hiss_timer = -1;
image_speed = 0;
image_index = (get_random_chance_out_of(2)) ? 1 : -1;