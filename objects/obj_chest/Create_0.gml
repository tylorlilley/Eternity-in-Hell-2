event_inherited();
var _current_room = global.controller.current_room;

// The room decides whether it's locked and what it holds: an item (special or not), a statue or fountain for a trapped
// chest, or -1 for nothing. It leaves dirt behind when destroyed.
closed = true;
locked = _current_room.has_locked_chest;
contents_obj = _current_room.chest_obj;
contents_is_special = _current_room.has_special_item;
remains_obj = obj_dirt;

// Leave a trapped chest off the map
if (_current_room.chest_obj == obj_statue) { _current_room.remove_from_instances_at_map_positions(id); }
if (_current_room.chest_obj == obj_fountain) { _current_room.remove_from_instances_at_map_positions(id); }