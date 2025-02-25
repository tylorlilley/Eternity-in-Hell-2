event_inherited();
sprite_index = get_sprite_to_use(spr_spider);

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
RETURNING = 3;
state = WAITING;
dir = directions.none;

can_move_on_border = true;
target_path_grid = global.controller.current_room.lava_path_grid;
has_automatic_target_path_generation = false;
start_waiting();

target_x = xstart;
target_y = ystart;
