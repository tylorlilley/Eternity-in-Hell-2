event_inherited();
depth = 6;

// Set up single death box for normal use case
death_box = instance_create_depth(x, y, 5, obj_death);
death_box.death_sound = snd_torchlight;
death_box.stopped_by_special_rosary = true;
death_boxes = noone;
