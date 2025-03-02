/// @description Step
event_inherited();
var player = global.player;
	
// Determine if bush is now is_occupied by an enemy or player
var new_occupier = noone;
var enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(enemies_at_position) > 0) {
	var enemy = array_random_pop(enemies_at_position);
	if (enemy.activated && !enemy.floating) { new_occupier = enemy; break; }
}
if (!is_existing_instance(new_occupier) && place_meeting(x, y, player)) { new_occupier = player; }
occupier = new_occupier;
	
// Rustle bush if is_occupied status changes, monster rustles it, or random rustling
var is_rustled_by_wind = get_random_chance_out_of(JUST_THE_WIND_PROBABILITY);
var is_rustled_by_occupier = ((is_existing_instance(occupier) && !is_occupied) || 
								(!is_existing_instance(occupier) && is_occupied) || 
								(is_existing_instance(occupier) && occupier != player && get_random_chance_out_of(BUSH_RUSTLE_FREQUENCY)));
			 
if (is_rustled_by_wind || is_rustled_by_occupier) {
	image_xscale *= -1;
	play_sound(snd_bush, is_rustled_by_occupier);
	is_occupied = (is_existing_instance(occupier));
	if (occupier == player) { 
		global.controller.evaluation_manager.increment_evaluation_variable("rustled_bushes");
	}
}
