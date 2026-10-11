event_inherited();

depth = COLLECTABLE_DEPTH;
sprite_index = get_sprite_to_use(spr_collectable);

// Whether it runs away from the player (the room's moving collectable), and the path it takes toward the player around
// solids when the special compass draws it in
moving = false;
target_path = noone;
target_path_grid = -1;
has_automatic_target_path_generation = true;
can_interrupt_target_path = false;
target_path_grid = global.controller.current_room.solid_path_grid;