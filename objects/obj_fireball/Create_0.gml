event_inherited();

depth = -300;
sprite_index = spr_fireball;
image_speed = one_unit_of_game_time();

// Torch Variables
torch = instance_create_depth(x, y, 5, obj_torch);
torch.special = true;
torch.holder = global.controller;
torch.time_to_remain_lit = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT;
torch.special = true;
torch.lighting_range = 5;
torch.light_source = instance_create_depth(x, y, 5, obj_light_source);
torch.light_source.lighting_range = 5;
torch.visible = false;
torch.sprite_index = spr_box;
torch.image_blend = c_lime;
torch.image_xscale = 0.5;
torch.image_yscale = 0.5;