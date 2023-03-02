/// @description End Step
event_inherited();
	
thump();
	
var push_direction = get_direction_pushed_against();
if (push_direction != directions.none) { play_sound(snd_locked, false); }
	
	
if (are_all_collectables_collected()) { break_heart_case(true); }