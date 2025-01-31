event_inherited();
end_target_path();

floating = true;
can_move_on_border = true;

sprite_timer = 6;
image_xscale = (get_coin_flip()) ? 1 : -1;

awake = false;
moved = false;
target_x = xstart;
target_y = ystart;

target_path_grid = global.controller.current_room.solid_path_grid;
