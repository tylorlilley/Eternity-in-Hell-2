draw_staff_box();

event_inherited();

is_carrying_item(obj_staff) { 
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);   
}

with (right_hand_item) { draw_while_carried(); } 