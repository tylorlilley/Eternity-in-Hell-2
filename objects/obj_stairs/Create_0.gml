event_inherited();
var controller = global.controller;

depth = STAIRS_DEPTH;
sprite_index = get_sprite_to_use(spr_stairs);

active = false;
connected_exit = controller.current_room.exits[directions.stairs];
if (connected_exit != -1) { connected_exit.add_stairs_for_room(controller.current_room, id); }