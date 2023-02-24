event_inherited();

/*
var controller = global.controller;
activated = get_random_chance_out_of(SPIDER_PROBABILITY);
if controller.entered_from_stairs { activated = false; }
*/

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
RETURNING = 3;
state = WAITING;
dir = directions.none;

can_move_on_border = true;
target_path_grid = global.controller.current_room.lava_grid;
has_automatic_target_path_generation = false;
start_waiting();

target_x = xstart;
target_y = ystart;
