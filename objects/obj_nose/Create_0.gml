event_inherited();

// Hidden under the lava until its spawn timer runs out, and fire doesn't hurt it
activated = false;
fire_resistant = true;

// Steps until it surfaces, and then steps until it shoots
spawn_timer = irandom_range(8, 32);
shoot_timer = 0;