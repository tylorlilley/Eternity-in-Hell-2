/// @description  transition_to_room
function transition_to_room(argument0) {
	var dir = argument0;

	// Play transition sound
	if (dir == 4) { sound_play(snd_stairs); }
	else { sound_play(snd_move); }

	// Change Rooms
	global.controller.entered_from_stairs = (dir == 4);
	global.controller.current_room = global.controller.current_room.adj_rooms[dir]; 
	room_goto(global.controller.current_room.room_reference);



}
