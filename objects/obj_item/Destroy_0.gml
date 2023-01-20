if (holder == global.player || (holder != noone && holder.object_index == obj_hands)) {
	with holder { put_down_item(other.id, false); }
}