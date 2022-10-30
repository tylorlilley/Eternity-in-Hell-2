/// @function								teleport_to_lava()
function teleport_to_lava() {
	var lava_at_quadrant = [];
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
		var lava_at_quadrant = get_presence_at_each_quadrant(obj_lava);
	}
	until (lava_at_quadrant[0] && lava_at_quadrant[1] && lava_at_quadrant[2] && lava_at_quadrant[3]);
}

/// @function								shoot_fireball()
///	@param		{int}	target_x		The x position of the target to move towards;
///	@param		{int}	target_y		The y position of the target to move towards;
function shoot_fireball(target_x, target_y) {
	audio_play_sound(snd_shoot, 10, false);
	with (instance_create_depth(x, y, 10, obj_fireball)) { move_towards_point(target_x, target_y, 2); }	
}