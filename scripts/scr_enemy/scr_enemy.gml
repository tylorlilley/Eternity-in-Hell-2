/// @function								kill_enemy();
function kill_enemy() {
	instance_destroy();
	audio_play_sound(death_sound, 10, false);
}

/// @function								run_away_from_player();
function run_away_from_player() {
	var dir = irandom(3);
	if (is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
	if (get_random_chance_out_of(3)) { dir = 4; }
	if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); }
}