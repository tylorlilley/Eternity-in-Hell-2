/// @description Step
if (x < 0 && y < 0 && !activated) { teleport_to_empty_space(); }

turn_to_face_player();

// Disapear and Reappear based on proximity to the player
var player = global.player, player_dist = get_distance_to_instance(player), dropped_meat = get_dropped_meat();
if (player_dist < TRAP_RANGE && !activated) {
	if (!is_existing_instance(dropped_meat) || (is_instance_at_coordinates(x, y, dropped_meat))) {
		activated = true; 
		play_sound(snd_squelch, true);
	}
	else {
		x = dropped_meat.x; 
		y = dropped_meat.y; 
	}
}
else if (player_dist >= TRAP_RANGE && activated) {
	activated = false; 
	play_sound(snd_squelch, true);
	teleport_to_empty_space();
}

// Animate Mouth
if (activated && get_distance_to_instance(player) < 24) { image_index = 2; }
else if (activated && get_distance_to_instance(player) < TRAP_RANGE-8) { image_index = 1; }
else if (activated && get_distance_to_instance(player) < TRAP_RANGE) { image_index = 0; }
	
event_inherited();