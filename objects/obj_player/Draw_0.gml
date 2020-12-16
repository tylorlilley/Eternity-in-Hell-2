if (carried_items[directions.left]) { draw_sprite_ext(spr_player_left_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
if (carried_items[directions.right]) { draw_sprite_ext(spr_player_right_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
    
event_inherited();

