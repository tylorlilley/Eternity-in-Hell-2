event_inherited();

depth = STAIRS_DEPTH;
sprite_index = get_sprite_to_use(spr_stairs);

active = false;
connected_to = global.controller.transitioned_from;
connected_room = global.controller.current_room;
