event_inherited();

// Draw Hands
var _x_pos = x-(8*image_xscale), _y_pos = y-(8*image_yscale);
draw_player_right_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);
draw_player_left_hand(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

// Draw hat in farm mode
draw_player_hat(_x_pos, _y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);