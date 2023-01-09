event_inherited();

thump_timer = 12;
sprite_index = (global.controller.FARM_MODE) ? spr_heart_farmer : spr_heart;
global.controller.completion_amount += 1;
image_speed = 0; // one_unit_of_game_time();
