/// @description  obj_game_object_move_in_direction(dir)
function obj_game_object_move_in_direction(argument0) {
	var dir = argument0;

	audio_play_sound( snd_walk, 10, false );
	if (dir == 0) { y -= 8; } 
	if (dir == 1) { x += 8; image_xscale = -1; }
	if (dir == 2) { y += 8; }
	if (dir == 3) { x -= 8; image_xscale = 1; }



}
