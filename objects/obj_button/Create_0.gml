event_inherited();


visible = false;
depth = 8;

// Destroy button and portcullis if button begins pressed
if (can_press_button()) { 
	instance_destroy();
	with (obj_portcullis) { instance_destroy(); }
	global.controller.current_room.has_portcullis = false;
}
else {
	var dirt_to_spawn = irandom(DIRT_PROBABILITY/2);
	for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }
}