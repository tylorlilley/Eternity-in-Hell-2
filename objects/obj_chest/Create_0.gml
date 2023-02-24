event_inherited();
var current_room = global.controller.current_room;

closed = true;
locked = current_room.has_locked_chest;
show_debug_message(object_get_name(object_index) + string(object_index))

if (current_room.chest_obj == obj_statue) { current_room.remove_from_instances_at_map_positions(id); }