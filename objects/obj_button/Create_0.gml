event_inherited();


visible = false;
depth = BUTTON_DEPTH;

// Destroy button and portcullis if button begins pressed
if (can_press_button()) { 
	instance_destroy();
	with (obj_portcullis) { instance_destroy(); }
	global.controller.current_room.remove_portcullis();
}
else {
	dirt = instance_create(x, y, obj_dirt);
	dirt.has_bug = true;
	var dirt_to_spawn = irandom(DIRT_PROBABILITY/2);
	for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }
}