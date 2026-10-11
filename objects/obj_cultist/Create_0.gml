event_inherited();

// Immune to magic, moves a quarter as often as a skeleton, and counts down to its magic beam and next teleport (see Step)
magic_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY*4;
shoot_timer = irandom_range(16, 32);

play_sound(snd_magicteleport, false);