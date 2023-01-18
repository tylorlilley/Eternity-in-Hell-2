event_inherited();

if (can_press_button()) { 
	instance_destroy();
	with (obj_portcullis) { instance_destroy(); }
}
instance_create_depth(x, y, 0, obj_dirt);
visible = false;