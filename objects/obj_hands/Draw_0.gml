draw_staff_box();

event_inherited();

is_carrying_item(obj_staff) { 
	draw_self();   
}

with (right_hand_item) { 
	draw_while_carried(); 
} 