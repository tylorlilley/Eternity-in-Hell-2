/// @description Draw

// Inherit the parent event
event_inherited();

// In the farmer graphics mode, draw the player's farmer hat over the echo
draw_player_hat(x-(8*image_xscale), y-(8*image_yscale), 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend);