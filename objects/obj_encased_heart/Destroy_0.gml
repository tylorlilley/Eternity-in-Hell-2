event_inherited();

// Remove the case from the part of the room the map draws it in
with (global.controller) { current_room.remove_from_instances_at_map_positions(other.id); }