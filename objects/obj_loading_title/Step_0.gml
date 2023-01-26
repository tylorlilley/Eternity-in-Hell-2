if (timer > 0) { timer -= 1; }
else {
	global.controller = instance_create(x, y, obj_controller);
	instance_destroy();
}