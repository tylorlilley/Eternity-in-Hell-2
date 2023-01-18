if (process_this_frame()) {
	event_inherited();
	
	// Determine if bush is now occupied
	var old_occupier = occupier, new_occupier = noone;
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		if (enemy.activated) { new_occupier = enemy; break; }
	}
	if (new_occupier == noone && place_meeting(x, y, global.player)) { new_occupier = global.player; }
	occupier = new_occupier;
	
	// Rustle bush if occupied status changes, monster rustles it, or random rustling
	if ((occupier && !occupied) || (!occupier && occupied) || get_random_chance_out_of(2056) ||
	   (occupier && occupier != global.player && get_random_chance_out_of(16))) {
			image_xscale *= -1;
			var just_the_wind = (!occupied && !occupier && !old_occupier);
			var ears_are_rustling = (instance_exists(old_occupier) && old_occupier.object_index == obj_ears) || (instance_exists(occupier) && occupier.object_index == obj_ears);
			play_sound(snd_bush, (!just_the_wind && !ears_are_rustling));
			occupied = (occupier != noone);
	}
}
