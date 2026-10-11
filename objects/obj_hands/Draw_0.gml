// A hand carrying a staff is drawn even where solids or bushes cover it, which the inherited Draw skips
draw_staff_box();

event_inherited();

if (is_carrying_item(obj_staff)) { 
	draw_self();   
}