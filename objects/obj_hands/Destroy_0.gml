instance_create_depth(x, y, 5, obj_blood);
with carried_items[1] {
	if (object_index == obj_rosary) {
		play_sound(snd_win, false);
		var new_hands = instance_create_depth(other.xstart, other.ystart, 0, obj_hands);
		new_hands.visible = true;
		new_hands.lethal = true;
		if (!special) { instance_destroy(); }
		else { new_hands.target_item = self; }
	}
	drop_item(1, false); 
}

