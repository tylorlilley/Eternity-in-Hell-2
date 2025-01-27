event_inherited();
var current_room = global.controller.current_room;

closed = true;
locked = current_room.has_locked_chest;

if (current_room.chest_obj == obj_statue) { current_room.remove_from_instances_at_map_positions(id); }
if (current_room.chest_obj == obj_fountain) { current_room.remove_from_instances_at_map_positions(id); }