event_inherited();

// Draw Hands
var x_pos = x-(8*image_xscale), y_pos = y-(8*image_yscale);
draw_player_right_hand(x_pos, y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);
draw_player_left_hand(x_pos, y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);

// Draw hat in farm mode
draw_player_hat(x_pos, y_pos, 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);