event_inherited();


visible = false;
depth = 8;

if (can_press_button()) { 
	instance_destroy();
	with (obj_portcullis) { instance_destroy(); }
	global.controller.current_room.has_portcullis = false;
}

var dirt_to_spawn = irandom(global.controller.DIRT_PROBABILITY/2);
for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }