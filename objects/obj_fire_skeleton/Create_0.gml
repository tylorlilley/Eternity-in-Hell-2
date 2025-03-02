event_inherited();

fire_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY;

shoot_timer = irandom_range(24, 48);

// Fake Projectile Variables
prev_speed = 0;
creator = id;
creator_obj = -1;
destructive = false;
shot_by_player = false;
consume_block = true;
torch = noone;

initialize_lava_lighting();

torch_light_image_timer = 0;
torch_light_sprite_index = spr_special_torch_light;
torch_light_image_index = 0;