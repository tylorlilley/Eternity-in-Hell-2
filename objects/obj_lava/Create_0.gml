depth = 5;
lighting_range = 4;
flicker_value = 0;
is_flickering_light_source = false;
death_box = instance_create_depth(x, y, 5, obj_death);
death_box.death_sound = snd_torchlight;

