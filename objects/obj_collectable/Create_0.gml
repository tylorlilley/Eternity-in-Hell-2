event_inherited();

image_speed = one_unit_of_game_time();
moving = get_random_chance_out_of(32-global.difficulty);
sprite_index = (global.controller.FARM_MODE) ? spr_collectable_farmer : spr_collectable;