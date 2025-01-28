event_inherited();
var current_room = global.controller.current_room;

closed = true;
locked = current_room.has_locked_chest;
contents_obj = current_room.chest_obj;
contents_is_special = current_room.has_special_item;
remains_obj = obj_dirt;

if (current_room.chest_obj == obj_statue) { current_room.remove_from_instances_at_map_positions(id); }
if (current_room.chest_obj == obj_fountain) { current_room.remove_from_instances_at_map_positions(id); }