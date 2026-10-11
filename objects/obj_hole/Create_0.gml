event_inherited();
var _controller = global.controller;

image_index = 0;
sprite_index = spr_hole;

flip_sprite_at_random(true);
rotate_sprite_to_random_angle();

// Holes dug with a shovel link up in pairs, like stairs between two rooms. The first hole of a pair starts an exit
// that leads nowhere yet, and the next hole dug completes it
if (_controller.last_hole_exit == -1) { 
	connected_exit = new RoomExit(_controller.current_room, -1);
	connected_exit.add_stairs_for_room(_controller.current_room, id);
	_controller.last_hole_exit = connected_exit;
}
else {
	connected_exit = _controller.last_hole_exit;
	connected_exit.room_2 = _controller.current_room;
	connected_exit.add_stairs_for_room(_controller.current_room, id);
	_controller.last_hole_exit = -1;
	
	// Show both holes on the map now that they're linked
	with (connected_exit.room_1) { add_to_instances_at_map_positions(other.connected_exit.room_1_stairs); }
	with (connected_exit.room_2) { add_to_instances_at_map_positions(other.connected_exit.room_2_stairs); }
}
