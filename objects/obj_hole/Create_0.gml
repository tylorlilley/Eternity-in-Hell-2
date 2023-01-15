event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_dirt : spr_bones;

depth = 4;
trap = false;

flip_sprite_at_random(true);
image_speed = 0;
image_index = irandom(5);

if (get_random_chance_out_of(32)) { instance_destroy(); instance_create_depth(x, y, 4, obj_blood); }