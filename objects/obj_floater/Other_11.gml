/// @description Step
var player = global.player;
if (x < 0 && y < 0 && !activated) { teleport_to_player(); }

if (!activated) {
	if (get_distance_to_instance(player) >= TRAP_RANGE) {
		direction = point_direction(x, y, player.x, player.y);
		play_sound(snd_whisper, false);
		activated = true;
	}
}
else {
	// Change angle of movement
	var new_dir = point_direction(x, y, player.x, player.y);
	var max_angle_change = 8, max_speed = 1.5, dir_difference = angle_difference(new_dir, direction);
	if (abs(dir_difference) < max_angle_change) { direction = new_dir; }
	else { 
		direction += sign(dir_difference) * max_angle_change; 
	}
	direction = (direction % 360);
	
	// Move in direction
	if (x != player.x) { x += lengthdir_x(max_speed, direction); }
	if (y != player.y) { y += lengthdir_y(max_speed, direction); }
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