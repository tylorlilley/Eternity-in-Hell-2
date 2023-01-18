event_inherited();
depth = 6;

// Set up single death box for normal use case
death_box = instance_create_depth(x, y, 5, obj_death);
death_box.lava = true;
death_boxes = noone;

// dirt = instance_create_depth(x, y, 0, obj_dirt);
