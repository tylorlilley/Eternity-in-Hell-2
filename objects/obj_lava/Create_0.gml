depth = 5;
lighting_range = 4;
flicker_value = 0;
is_flickering_light_source = false;

// Set up single death box for normal use case
death_box = instance_create_depth(x, y, 5, obj_death);
death_box.death_sound = snd_torchlight;
death_boxes = noone;
