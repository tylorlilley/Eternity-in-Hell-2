event_inherited();

sprite_index = spr_collectable;
image_speed = one_unit_of_game_time();

moving = get_random_chance_out_of(32-global.difficulty);

set_farm_mode_sprite(spr_collectable_farmer);