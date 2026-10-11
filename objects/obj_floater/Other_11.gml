/// @description Step
var _player = global.player;
// A floater starts off the map, and appears where the player entered the room
if (x < 0 && y < 0 && !activated) { teleport_to_player(); }

// A dormant floater wakes with a whisper once the player is at least TRAP_RANGE pixels away, and drifts towards them
if (!activated) {
	if (get_distance_to_instance(_player) >= TRAP_RANGE) {
		direction = point_direction(x, y, _player.x, _player.y);
		play_sound(snd_whisper, false);
		activated = true;
	}
}
else {
	// Turn towards the player, by at most 8 degrees a step
	var _new_dir = point_direction(x, y, _player.x, _player.y);
	var _max_angle_change = 8, _max_speed = 1.75, _dir_difference = angle_difference(_new_dir, direction);
	if (abs(_dir_difference) < _max_angle_change) { direction = _new_dir; }
	else { 
		direction += sign(_dir_difference) * _max_angle_change; 
	}
	direction = (direction % 360);
	
	// Fly in that direction, at up to 1.75 pixels a step and through anything in the way
	if (x != _player.x) { x += lengthdir_x(_max_speed, direction); }
	if (y != _player.y) { y += lengthdir_y(_max_speed, direction); }
	// Half the steps it flickers, with a sound: it switches frames (or, one time in 32, shows its third frame) and
	// faces the player
	if (get_coin_flip()) { 
		play_sound(snd_flicker, false);
		if (get_random_chance_out_of(32)) { image_index = 2; }
		else {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
		}
		turn_to_face_player();
	}
}

event_inherited();