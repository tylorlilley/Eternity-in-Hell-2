event_inherited();

fire_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY;
creator = self;
torch = initialize_fireball_torch_variables(LAVA_LIGHT_RANGE);

shoot_timer = irandom_range(24, 48);