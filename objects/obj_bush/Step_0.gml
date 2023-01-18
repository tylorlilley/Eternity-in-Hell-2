if (process_this_frame()) {
	event_inherited();
	
	// Determine if bush is now occupied
	var old_occupier = occupier
	if (instance_place(x,y,obj_enemy)) { occupier = instance_place(x,y,obj_enemy); }
	else if (instance_place(x,y,global.player)) { occupier = global.player; }
	else { occupier = noone; }
	
	// Rustle bush if occupied status changes, monster rustles it, or random rustling
	if ((occupier && !occupied) || (!occupier && occupied) || get_random_chance_out_of(2056) ||
	   (occupier && occupier != global.player  && occupier.activated && get_random_chance_out_of(16))) {
			image_xscale *= -1;
			var just_the_wind = (!occupied && !occupier && !old_occupier);
			var ears_are_rustling = (instance_exists(old_occupier) && old_occupier.object_index == obj_ears) || (instance_exists(occupier) && occupier.object_index == obj_ears);
			play_sound(snd_bush, (!just_the_wind && !ears_are_rustling));
			occupied = (occupier != noone);
	}
}
