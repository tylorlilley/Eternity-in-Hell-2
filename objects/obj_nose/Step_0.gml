if (process_this_frame()) {
	event_inherited();
	
	if (spawn_timer > 0) { visible = false; spawn_timer -= 1; }
	else {
		if (!visible) { 
			teleport_to_lava();
			visible = true; 
			shoot_timer = 16; //irandom_range(6, 16);
			turn_to_face_player();
			play_sound(snd_splash, true);
		}
		else if (shoot_timer > 0) { shoot_timer -= 1; turn_to_face_player(); }
		if (shoot_timer == 4) {
			image_index = 1;
		}
		else if (shoot_timer == 0) {
			shoot_fireball(global.player.x, global.player.y);
			visible = false;
			image_index = 0;
			spawn_timer = irandom_range(8, 64);
		}
	}
}
