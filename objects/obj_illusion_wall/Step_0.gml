event_inherited();

if (can_process_this_frame()) {
	if (instance_place(x, y, global.player) || instance_place(x, y, obj_enemy) || instance_place(x, y, obj_fireball)) {
		visible = (modulo(global.game_manager.number_of_frames_since_game_began, (FRAMES_TO_WAIT_BEFORE_PROCESSING * 2)) == 0); 
	}
	else { visible = true; }
	
	/*
	else if (get_random_chance_out_of(ILLUSION_WALL_FLICKER_FREQUENCY)) { visible = false; play_sound(snd_flicker, false); }
	else { visible = true; }
	*/
}
