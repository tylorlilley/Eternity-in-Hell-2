/// @description Step

if (x < 0 && y < 0 && !activated) { teleport_to_lava(); }

if (!is_covered_at_each_quadrant_by(obj_lava_part)) { reset_nose(); }
	
if (spawn_timer > 0) { activated = false; spawn_timer -= 1; }
else {
	if (!activated) {
		activated = true; 
		shoot_timer = 16; //irandom_range(6, 16);
		turn_to_face_player();
		play_sound(snd_splash, false);
	}
	else if (shoot_timer > 0) { shoot_timer -= 1; turn_to_face_player(); }
	if (shoot_timer == 4) {
		image_index = 1;
	}
	else if (shoot_timer == 0) {
		if (get_random_chance_out_of(NOSE_SELF_DESTRUCT_PROBABILITY)) { explode(true); } 
		else {
			var target = get_dropped_meat();
			if (!is_existing_instance(target)) { target = global.player; }
			shoot_projectile(target.x, target.y, false);
			reset_nose();
		}
	}
}

event_inherited();
