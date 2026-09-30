/// @description Draw

// Inherit the parent event
event_inherited();

// Draw hat in farm mode
draw_player_hat(x-(8*image_xscale), y-(8*image_yscale), 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);