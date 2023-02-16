event_inherited();
var controller = global.controller;

image_index = 0;
sprite_index = spr_hole;

flip_sprite_at_random(true);
rotate_sprite_to_random_angle();

if (controller.last_hole_exit == -1) { 
	connected_exit = new RoomExit(controller.current_room, -1);
	connected_exit.add_stairs_for_room(controller.current_room, id);
	controller.last_hole_exit = connected_exit;
}
else {
	connected_exit = controller.last_hole_exit;
	connected_exit.room_2 = controller.current_room;
	connected_exit.add_stairs_for_room(controller.current_room, id);
	controller.last_hole_exit = -1;
}
