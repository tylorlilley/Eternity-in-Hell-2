/// @description Step
// A mouth parked outside the room, as a new one is, picks a spot in the room to hide in
if (x < 0 && y < 0 && !activated) { teleport_to_empty_space(); }

turn_to_face_player();

// Appear and disappear depending on how close the player is
var _player = global.player, _player_dist = get_distance_to_instance(_player), _dropped_meat = get_dropped_meat();
if (_player_dist < TRAP_RANGE && !activated) {
	// A hidden mouth appears once the player is within trap range, where it is. If meat has been dropped, it first
	// moves onto the meat, and appears there on the next step
	if (!is_existing_instance(_dropped_meat) || (is_instance_at_coordinates(x, y, _dropped_meat))) {
		activated = true; 
		play_sound(snd_squelch, true);
	}
	else {
		x = _dropped_meat.x; 
		y = _dropped_meat.y; 
	}
}
else if (_player_dist >= TRAP_RANGE && activated) {
	// When the player is out of range again, it disappears and hides in a new spot
	activated = false; 
	play_sound(snd_squelch, true);
	teleport_to_empty_space();
}

// Open wider the closer the player is: the last frame within 24 pixels
if (activated && get_distance_to_instance(_player) < 24) { image_index = 2; }
else if (activated && get_distance_to_instance(_player) < TRAP_RANGE-8) { image_index = 1; }
else if (activated && get_distance_to_instance(_player) < TRAP_RANGE) { image_index = 0; }
	
event_inherited();