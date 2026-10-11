/// @description Step
event_inherited();
var _player = global.player;
	
if (is_existing_instance(closed)) {
	// Set up door interaction variables
	var _locked = (door_for_exit != -1 && door_for_exit.has_lock), _carrying_key = false, _push_direction = get_direction_pushed_against();
	if (_locked) { image_index = 2; }
	with (_player) { _carrying_key = is_carrying_item(obj_key); }
		
	// Door is being pushed against
	if (_push_direction != directions.none) {
		if (!unlocked_by_key || (_locked && !_carrying_key)) { 
			play_sound(snd_locked, false);
			with (door_for_exit) { visited = true; }
		}
		else {
			// Open Door
			increment_run_stat("opened_doors");
			open_door();
			with (_player) { play_sound(snd_open, true); }
			snap_player_to_position(_push_direction);
			move_player(_push_direction);
		}
	}
}
else if (!stuck_open && !place_meeting(x, y, _player) && !place_meeting(x, y, obj_enemy) && !place_meeting(x, y, obj_solid)) {
	// Close Door
	if (!is_outside_room(_player.x, _player.y)) { play_sound(close_sound, false); }
	close_door();
}
