event_inherited();

depth = -300;
image_speed = get_one_unit_of_game_time();

creator_obj = -1;
destructive = false;

// Torch Variables
torch = instance_create(x, y, obj_torch);
torch.special = true;
torch.holder = id;
torch.time_to_remain_lit = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT;
torch.special = true;
torch.lighting_range = 3;
torch.light_source = instance_create(x, y, obj_light_source);
torch.light_source.lighting_range = 3;
torch.visible = false;
torch.sprite_index = spr_box;
torch.image_blend = c_lime;
torch.image_xscale = 0.5;
torch.image_yscale = 0.5;