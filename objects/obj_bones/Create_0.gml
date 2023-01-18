event_inherited();
set_farm_mode_sprite(spr_dirt);

depth = 4;
image_index = irandom(5);

trap = false;

flip_sprite_at_random(true);
if (get_random_chance_out_of(global.controller.BLOOD_REPLACEMENT_PROBABILITY)) { instance_destroy(); instance_create_depth(x, y, 4, obj_blood); }