event_inherited();
depth = 9;

// Set up single death box for normal use case
death_box = instance_create(x, y, obj_death);
death_box.creator_obj = object_index;
death_boxes = noone;

/*
light_source = instance_create(x, y, obj_light_source);
light_source.lighting_range = 2;
light_source.is_flickering_light_source = false;
light_source.flicker_value = 0;
*/