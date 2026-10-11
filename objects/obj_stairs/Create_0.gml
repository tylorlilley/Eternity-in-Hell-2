event_inherited();
var _controller = global.controller;

depth = STAIRS_DEPTH;
sprite_index = get_sprite_to_use(spr_stairs);

active = false;
connected_exit = _controller.current_room.exits[directions.stairs];
if (connected_exit != -1) { connected_exit.add_stairs_for_room(_controller.current_room, id); }