/// @function								try_to_see_player();
function try_to_see_player(){
	var new_dir = noone;
	if (global.player.x == x) {
	    if (global.player.y > y) { new_dir = directions.down; }
	    else { new_dir = directions.up; }
	}
	else if (global.player.y == y) {
	    if (global.player.x > x) { new_dir = directions.right; }
	    else { new_dir = directions.left; }
	}
			
	if (new_dir != noone && new_dir != dir && can_move_in_direction_and_reach(new_dir, global.player, false, true)) {
		dir = new_dir;
		state = SCREECHING;
		screech_timer = 4;
		audio_play_sound( snd_lose, 10, false ); 
	}
}