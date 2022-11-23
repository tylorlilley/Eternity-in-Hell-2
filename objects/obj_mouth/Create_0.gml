event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_mouth_farmer : spr_mouth;
killable_by_sword = true;
consume_block = true;
consumed_by_block = true;
//consumed_by_lava = true;
death_sound = snd_crunch;
visible = false;

MOUTH_DISTANCE = 40;
