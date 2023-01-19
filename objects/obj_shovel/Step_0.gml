if (holder != noone && holder != global.controller && !damaged) { sprite_index = spr_shovel; }
else if (holder != noone && holder != global.controller && damaged) { sprite_index = spr_worn_shovel; }
else if (holder == noone && !damaged) {
	if (can_make_hole()) { sprite_index = spr_shovel_in_ground; }
	else { sprite_index = spr_shovel; }
}
else if (holder == noone && damaged) { 
	if (can_make_hole()) { sprite_index = spr_worn_shovel_in_ground; }
	else { sprite_index = spr_worn_shovel; }
}

event_inherited();
