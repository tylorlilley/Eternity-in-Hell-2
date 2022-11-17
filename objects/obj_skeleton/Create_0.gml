event_inherited();

killable_by_sword = true;
consumed_by_block = true;
consumed_by_lava = true;
death_sound = snd_crunch;
spawn_timer = 3+irandom(3);
skeleton_speed = (get_random_chance_out_of(global.controller.FAST_SKELETON_PROBABILITY)) ?  4 : 12; 
image_speed = (skeleton_speed == 4) ? 1 : 0;

usurped = noone;
if (get_random_chance_out_of(global.controller.WORM_PROBABILITY)) { usurped = obj_worm; }
if (get_random_chance_out_of(global.controller.EYES_PROBABILITY)) { usurped = obj_bumper; }