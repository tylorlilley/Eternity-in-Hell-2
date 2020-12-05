door_for_exit = noone;
image_speed = 0;

if (x == room_width/2) dir = 0;
else if (x < room_width/2) { dir = 1; }
else if (x > room_width/2) { dir = 3; }
//image_angle = dir * 90;

locked = false;
closed = instance_create(x, y, obj_solid);
closed.visible = false;

