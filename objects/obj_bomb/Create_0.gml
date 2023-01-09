event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_bomb_farmer : spr_bomb;
draw_y_offset = -2;
fuse_timer = 4*irandom_range(5,8);
