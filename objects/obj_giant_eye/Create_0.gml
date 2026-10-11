#macro GIANT_EYE_PARTS_COUNT 9

event_inherited();

depth = GIANT_WORM_DEPTH-1;		// Just above its eye parts, so the pupil shows over them
pupil_sprite = get_sprite_to_use(spr_giant_eye_pupil);
dying = 0;						// Counts down from 32 through its death animation, and stays 0 while it's alive
spin_counter = 0;				// How far the pupil has moved without stopping: past 512, the eye dies
shoot_timer = irandom_range(18,24);
pupil_x = x;
pupil_y = y;

flip_sprite_at_random(true);
rotate_sprite_to_random_angle();

// The nine instances that draw the eye itself in a 3x3 grid, made on the room's first visit (see game_room_start)
eye_parts = array_create(GIANT_EYE_PARTS_COUNT);
