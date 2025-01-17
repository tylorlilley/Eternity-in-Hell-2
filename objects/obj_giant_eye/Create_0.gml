event_inherited();

depth = -1;
dying = 0;
spin_counter = 0;
shoot_timer = irandom_range(24,48);
pupil_x = x;
pupil_y = y;

flip_sprite_at_random(true);
rotate_sprite_to_random_angle();