/// @description Step
event_inherited();
var _player = global.player;
	
// Determine if bush is now is_occupied by an enemy or player
var _new_occupier = noone;
var _enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(_enemies_at_position) > 0) {
	var _enemy = array_random_pop(_enemies_at_position);
	if (_enemy.activated && !_enemy.floating) { _new_occupier = _enemy; break; }
}
if (!is_existing_instance(_new_occupier) && place_meeting(x, y, _player)) { _new_occupier = _player; }
occupier = _new_occupier;
	
// Rustle bush if is_occupied status changes, monster rustles it, or random rustling
var _is_rustled_by_wind = get_random_chance_out_of(JUST_THE_WIND_PROBABILITY);
var _is_rustled_by_occupier = ((is_existing_instance(occupier) && !is_occupied) || 
								(!is_existing_instance(occupier) && is_occupied) || 
								(is_existing_instance(occupier) && occupier != _player && get_random_chance_out_of(BUSH_RUSTLE_FREQUENCY)));
			 
if (_is_rustled_by_wind || _is_rustled_by_occupier) {
	image_xscale *= -1;
	play_sound(snd_bush, _is_rustled_by_occupier);
	is_occupied = (is_existing_instance(occupier));
	if (occupier == _player) { 
		global.controller.evaluation_manager.increment_evaluation_variable("rustled_bushes");
	}
}
