event_inherited();
depth = 12;

// Set up single death box for normal use case
death_box = instance_create(x, y, obj_death);
death_box.creator = id;
death_boxes = noone;

// Set up lava edge tiles
lava_edge_image_indexes = [[noone, noone, noone, noone], [noone, noone, noone, noone], [noone, noone, noone, noone], [noone, noone, noone, noone]];
lava_edge_image_xscales = [[noone, noone, noone, noone], [noone, noone, noone, noone], [noone, noone, noone, noone], [noone, noone, noone, noone]];
lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]];
