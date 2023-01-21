var sprite = sprite_index = (damaged) ? spr_worn_shovel_in_ground : spr_shovel_in_ground;
if (!dropped_by_digger || holder != noone || !can_make_hole()) { sprite = (damaged) ?  spr_worn_shovel : spr_shovel; }

sprite_index = get_sprite_to_use(sprite);

event_inherited();
