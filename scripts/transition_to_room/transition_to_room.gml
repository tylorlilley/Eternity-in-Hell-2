/// @function								transition_to_room(dir);
/// @param		{direction} dir				The direction in which the player is moving when leaving the current room
function transition_to_room(dir) {
	// Play transition sound
	if (dir == 4) { audio_play_sound( snd_stairs, 10, false ); }
	else { audio_play_sound( snd_move, 10, false ); }

	// Change Rooms
	global.controller.entered_from_stairs = (dir == 4);
	global.controller.current_room = global.controller.current_room.adj_rooms[dir]; 
	room_goto(global.controller.current_room.room_reference);
}
