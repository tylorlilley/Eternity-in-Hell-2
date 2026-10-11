// Mark its exit's door as destroyed, remove the solid that blocked the way, and leave dirt behind during a game
if (door_for_exit != -1) { door_for_exit.destroy(); }
with (closed) { instance_destroy(); }
if (is_existing_instance(global.controller)) { instance_create(x, y, obj_dirt); }