event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_worm_farmer : spr_worm;

killable_by_sword = true;
consume_block = false
consumed_by_block = true;
consumed_by_lava = true;
death_sound = snd_crunch;
image_speed = 1;

dir = -1;

