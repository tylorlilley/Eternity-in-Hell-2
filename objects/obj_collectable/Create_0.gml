event_inherited();

depth = COLLECTABLE_DEPTH;
sprite_index = get_sprite_to_use(spr_collectable);

moving = false;
target_path = noone;
target_path_grid = -1;
has_automatic_target_path_generation = true;
can_interrupt_target_path = false;
target_path_grid = global.controller.current_room.solid_path_grid;