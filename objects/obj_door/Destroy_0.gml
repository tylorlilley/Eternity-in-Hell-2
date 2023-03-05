if (door_for_exit != -1) { door_for_exit.destroy(); }
with (closed) { instance_destroy(); }
if (is_existing_instance(global.controller)) { instance_create(x, y, obj_dirt); }