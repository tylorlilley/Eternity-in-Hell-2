event_inherited();

killable_by_sword = true;
consumed_by_block = true;
consumed_by_lava = true;
death_sound = snd_crunch;
spawn_timer = 3+irandom(3);
skeleton_speed = (get_random_chance_out_of(10-global.difficulty)) ?  4 : 12; 
image_speed = (skeleton_speed == 4) ? 1 : 0;

usurped = get_random_chance_out_of(32-global.difficulty);