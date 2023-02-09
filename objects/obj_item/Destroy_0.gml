global.controller.current_room.remove_from_instances_at_map_positions(id);

with (holder) {
	if (object_index == obj_player || object_index == obj_hands) {
		put_down_item(other.id, false, false);
	}
}