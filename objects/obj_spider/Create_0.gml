event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_spider_farmer : spr_spider;

meat_eater = true;
killable_by_sword = true;
consume_block = false
consumed_by_block = true;
consumed_by_lava = true;
lethal = get_random_chance_out_of(2);
death_sound = snd_crunch;

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
MEAT = 3;
state = WAITING;
dir = -1;
