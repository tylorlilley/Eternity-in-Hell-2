// Stop the map from showing it
with (global.controller) { current_room.remove_from_instances_at_map_positions(other.id); }

// Free the hand of the player or hands enemy that carries it, without the noise of putting it down
with (holder) {
	if (object_index == obj_player || object_index == obj_hands) {
		put_down_item(other.id, false, false);
	}
}