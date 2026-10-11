/// @description End Step
event_inherited();
	
// The heart thumps in time with the game's heartbeat
thump();
	
// Pushing against the case plays the locked sound, as it won't open
var _push_direction = get_direction_pushed_against();
if (_push_direction != directions.none) { play_sound(snd_locked, false); }
	
	
// The case breaks, with a screen flash, once every collectable is collected
if (are_all_collectables_collected()) { break_heart_case(true); }