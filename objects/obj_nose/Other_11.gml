/// @description Step

// A nose parked outside the room, as a new one is, moves to a spot of lava
if (x < 0 && y < 0 && !activated) { teleport_to_lava(); }

// A nose needs lava over all four of its quadrants. If some has gone, it hides again and moves to other lava
if (!is_covered_at_each_quadrant_by(obj_lava_part)) { reset_nose(); }
	
// Stay hidden until the spawn timer runs out
if (spawn_timer > 0) { activated = false; spawn_timer -= 1; }
else {
	// Surface, then count down to a shot: it faces its target as it surfaces and all through the countdown
	if (!activated) {
		activated = true; 
		shoot_timer = 16;
		turn_to_face_player();
		play_sound(snd_splash, false);
	}
	else if (shoot_timer > 0) { shoot_timer -= 1; turn_to_face_player(); }
	// Four steps before it shoots, it switches to its shooting frame
	if (shoot_timer == 4) {
		image_index = 2;
	}
	else if (shoot_timer == 0) {
		// Shoot a fireball at the target (the dropped meat, or else the player) and go back under the lava, or very
		// rarely explode instead
		if (get_random_chance_out_of(NOSE_SELF_DESTRUCT_PROBABILITY)) { explode(true); } 
		else {
			var _target = get_dropped_meat();
			if (!is_existing_instance(_target)) { _target = global.player; }
			shoot_projectile(_target.x, _target.y, false);
			reset_nose();
		}
	}
}

event_inherited();
