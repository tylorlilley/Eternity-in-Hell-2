event_inherited();
depth = 9;

// Set up single death box for normal use case
death_box = instance_create_depth(x, y, 0, obj_death);
death_box.creator = id;
death_boxes = noone;

// dirt = instance_create_depth(x, y, 0, obj_dirt);
