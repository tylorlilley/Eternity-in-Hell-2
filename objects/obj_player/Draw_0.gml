// Draw box over lava or staff solids
draw_staff_box();

// Draw main sprite
event_inherited();

// Draw carried items
with (left_hand_item) { draw_while_carried(); } 
with (right_hand_item) { draw_while_carried(); } 

// Draw Hands
if ((image_xscale == 1 && is_existing_instance(left_hand_item)) || (image_xscale == -1 && is_existing_instance(right_hand_item))) {
	draw_sprite_ext(spr_player_left_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}
if ((image_xscale == -1 && is_existing_instance(left_hand_item)) || (image_xscale == 1 && is_existing_instance(right_hand_item))) {
	draw_sprite_ext(spr_player_right_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

// Draw hat in farm mode
draw_player_hat();