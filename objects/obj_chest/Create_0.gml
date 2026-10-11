event_inherited();
var _current_room = global.controller.current_room;

closed = true;
locked = _current_room.has_locked_chest;
contents_obj = _current_room.chest_obj;
contents_is_special = _current_room.has_special_item;
remains_obj = obj_dirt;

if (_current_room.chest_obj == obj_statue) { _current_room.remove_from_instances_at_map_positions(id); }
if (_current_room.chest_obj == obj_fountain) { _current_room.remove_from_instances_at_map_positions(id); }