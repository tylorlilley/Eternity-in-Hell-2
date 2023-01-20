if (holder != noone && holder != global.controller && !damaged) { sprite_index = get_sprite_to_use(spr_shovel); }
else if (holder != noone && holder != global.controller && damaged) { sprite_index = get_sprite_to_use(spr_worn_shovel); }
else if (holder == noone && !damaged) {
	if (can_make_hole()) { sprite_index = get_sprite_to_use(spr_shovel_in_ground); }
	else { sprite_index = get_sprite_to_use(spr_shovel); }
}
else if (holder == noone && damaged) { 
	if (can_make_hole()) { sprite_index = get_sprite_to_use(spr_worn_shovel_in_ground); }
	else { sprite_index = get_sprite_to_use(spr_worn_shovel); }
}

event_inherited();
