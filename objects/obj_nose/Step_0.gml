if (process_this_frame()) {
	if (spawn_timer > 0) { visible = false; spawn_timer -= 1; }
	else {
		if (!visible) { 
			teleport_to_lava();
			visible = true; 
			shoot_timer = 16; //irandom_range(6, 16);
			turn_to_face_player();
			play_sound(snd_splash, false);
		}
		else if (shoot_timer > 0) { shoot_timer -= 1; turn_to_face_player(); }
		if (shoot_timer == 4) {
			image_index = 1;
		}
		else if (shoot_timer == 0) {
			if (get_random_chance_out_of(128*global.difficulty)) { explode(true); } 
			else {
				var target = global.player;
				with (obj_meat) { if (!carried) { target = self; } }
				shoot_fireball(target.x, target.y);
				visible = false;
				image_index = 0;
				spawn_timer = irandom_range(8, 64);
			}
		}
	}
	
	lethal = visible;
	
	var lava_at_quadrant = lava_at_position();
	if (lava_at_quadrant[0] == noone || lava_at_quadrant[1] == noone || lava_at_quadrant[2] == noone ||lava_at_quadrant[3] == noone) {
		teleport_to_lava();
	}
	
	event_inherited();
}
