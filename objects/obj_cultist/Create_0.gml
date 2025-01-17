event_inherited();

magic_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY*4;
creator = self;
torch = initialize_fireball_torch_variables(LAVA_LIGHT_RANGE);

shoot_timer = irandom_range(24, 48);