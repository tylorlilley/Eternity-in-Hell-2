event_inherited();

depth = GIANT_WORM_DEPTH-1;
pupil_sprite = get_sprite_to_use(spr_giant_eye_pupil);
dying = 0;
spin_counter = 0;
shoot_timer = irandom_range(18,24);
pupil_x = x;
pupil_y = y;

flip_sprite_at_random(true);
rotate_sprite_to_random_angle();

eye_parts = array_create(0);
