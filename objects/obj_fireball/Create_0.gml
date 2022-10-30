event_inherited();

depth = -300;
sprite_index = spr_collectable;
image_speed = one_unit_of_game_time();
image_blend = c_red;

// Create Deathbox
death_box = instance_create_depth(x, y, 5, obj_death);
death_box.death_sound = snd_torchlight;
death_box.stopped_by_special_rosary = true;
death_box.visible = false;
death_box.image_xscale = 0.5;
death_box.image_yscale = 0.5;
		
// Torch Variables
torch = instance_create_depth(x, y, 5, obj_torch);
torch.special = true;
torch.carried = global.controller;
torch.time_to_remain_lit = -1;
torch.lighting_range = 5;
torch.light_source = instance_create_depth(x, y, 5, obj_light_source);
torch.light_source.lighting_range = 5;
torch.visible = false;
torch.sprite_index = spr_box;
torch.image_xscale = 0.5;
torch.image_yscale = 0.5;