event_inherited();

if (can_press_button()) { 
	instance_destroy();
	with (obj_portcullis) { instance_destroy(); }
}

var dirt_to_spawn = irandom(global.controller.DIRT_PROBABILITY);
for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }
instance_create_depth(x, y, 0, obj_dirt);
visible = false;