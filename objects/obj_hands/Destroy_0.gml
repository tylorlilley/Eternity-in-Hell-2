with (right_hand_item) {
	if (object_index == obj_rosary) {
		var new_hands = instance_create_depth(other.xstart, other.ystart, 0, obj_hands);
		new_hands.death_timer = global.controller.RESPAWN_FREQUENCY;
		if (!special) { instance_destroy(); }
		else { new_hands.target_item = id; }
	}
	become_dropped(other.id); 
}


if (target_item != noone && target_item.holder == global.controller) { target_item.holder = noone; }