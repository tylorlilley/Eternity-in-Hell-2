event_inherited();

depth = GIANT_WORM_DEPTH;

// The segments ahead of it and behind it in the worm (see connect_segments)
head = noone;
tail = noone;
// Its next two moves, in order. Segments sit 16 pixels apart and move 8 at a time, so each one repeats the moves of
// the segment ahead of it two moves later (see move_segments)
dir = directions.none;
prev_dir = directions.none;

// The extra tile that fills the corner where the worm turns between it and the segment ahead (see End Step)
corner_x = x;
corner_y = y;
corner_x_scale = 1; 
corner_y_scale = 1;
corner_blend = image_blend;