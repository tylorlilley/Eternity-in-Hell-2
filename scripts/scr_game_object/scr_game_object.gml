/// @function								distance_to_instance(instance);
/// @param		{index} instance			The instance whose distance away from the calling instance is to be calculated
function distance_to_instance(instance) {
	if (!instance_exists(instance)) { return -1; }
	if (self.id == instance.id) { return 0; }

	return sqrt((sqr(instance.x - x) + sqr(instance.y - y)));
}

/// @function								is_direction_toward_player(dir);
/// @param		{direction} dir				The direction from the calling instance to check whether the player is in or not
function is_direction_toward_player(dir) {
	return ((y > global.player.y && dir == 0) ||
	        (x < global.player.x && dir == 1) ||
	        (y < global.player.y && dir == 2) ||
	        (x > global.player.x && dir == 3));
}

/// @function								turn_to_face_player();
function turn_to_face_player() {
	if (is_direction_toward_player(1)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function  							teleport_near_player();
function teleport_near_player() {
	audio_play_sound( snd_flicker, 10, false );

	do {
	    var x_pos = (8*irandom(3));
	    var y_pos = (8*irandom(3));
	    if (get_random_chance_out_of(2)) { x_pos *= -1; }
	    if (get_random_chance_out_of(2)) { y_pos *= -1; }
	    x = global.player.x + x_pos;
	    y = global.player.y + y_pos;
	}
	until (distance_to_instance(global.player) >= 24 && y >= 0 && y <= room_height && x >= 0 && x <= room_width);
}


/// @function								can_move_in_direction(dir, ignore_solid);
/// @param		{direction}					The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
function can_move_in_direction(dir, ignore_solid) {
	return (!global.controller.key_space && 
	    (dir == 0 && (ignore_solid || !instance_place(x, y-8, obj_solid)) && (object_index == obj_player || y-8 > 0)) ||
	    (dir == 2 && (ignore_solid || !instance_place(x, y+8, obj_solid)) && (object_index == obj_player || y+8 < room_height)) ||
	    (dir == 3 && (ignore_solid || !instance_place(x-8, y, obj_solid)) && (object_index == obj_player || x-8 > 0)) ||
	    (dir == 1 && (ignore_solid || !instance_place(x+8, y, obj_solid)) && (object_index == obj_player || x+8 < room_width)));
}


/// @function								move_in_direction(dir);
/// @param		{direction}					The direction in which to move the calling instance
function move_in_direction(dir) {
	audio_play_sound( snd_walk, 10, false );
	
	if (dir == 0) { y -= 8; } 
	if (dir == 1) { x += 8; image_xscale = -1; }
	if (dir == 2) { y += 8; }
	if (dir == 3) { x -= 8; image_xscale = 1; }
}


/// @function								set_instance_to_same_position(instance);
/// @param		{index} instance			The instance to set to the same position as the calling instance
function set_instance_to_same_position(instance) {
	with instance { 
	    x = other.x; 
	    y = other.y; 
	    image_xscale = other.image_xscale; 
	}
}

/// @function								audio_play_sound_for_object_only_once();
/// @param		{index} sound_to_play		The sound to play only once
function audio_play_sound_for_object_only_once(sound_to_play) {
	if ((instance_number(object_index) > 0) && instance_find(object_index, 0).id == id) { audio_play_sound( sound_to_play, 10, false ); }
}
