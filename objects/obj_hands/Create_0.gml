event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_hands_farmer : spr_hands;
visible = false;
lethal = false;
carried_items = [noone, noone, noone, noone, noone];

meat_eater = true;
killable_by_sword = true;
consumed_by_block = true;
consumed_by_lava = true;
death_sound = snd_crunch;
image_speed = 1;
target_item = noone;

TRAP_DISTANCE = 40;