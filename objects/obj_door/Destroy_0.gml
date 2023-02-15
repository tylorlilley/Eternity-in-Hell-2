if (door_for_exit != -1) { door_for_exit.destroy(); }
with (closed) { instance_destroy(); }
instance_create(x, y, obj_dirt);