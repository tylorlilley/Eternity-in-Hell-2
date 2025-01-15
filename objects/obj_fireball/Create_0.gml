event_inherited();

depth = FIREBALL_DEPTH;
image_speed = get_one_unit_of_game_time() * 2;

creator = noone;
creator_obj = -1;
destructive = false;

// Torch Variables
torch = initialize_fireball_torch_variables(FIREBALL_LIGHT_RANGE)