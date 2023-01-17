if (carried == noone && !has_been_carried) { sprite_index = spr_shovel; }
else if (carried != noone && !damaged) { sprite_index = spr_shovel; }
else if (carried != noone && damaged) { sprite_index = spr_worn_shovel; }
else if (carried == noone && !damaged) { sprite_index = spr_shovel_in_ground; }
else if (carried == noone && damaged) { sprite_index = spr_worn_shovel_in_ground; }

event_inherited();
