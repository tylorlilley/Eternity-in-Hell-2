event_inherited();

fire_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY;
torch = noone//initialize_fireball_torch_variables(LAVA_LIGHT_RANGE);

shoot_timer = irandom_range(24, 48);

// Fake Projectile Variables
prev_speed = 0;
creator = self;
creator_obj = -1;
destructive = false;
shot_by_player = false;

initialize_lava_lighting();