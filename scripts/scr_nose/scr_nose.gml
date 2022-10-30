/// @function								teleport_to_lava()
function teleport_to_lava() {
	var lava_at_quadrant = [];
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
		var lava_at_quadrant = get_presence_at_each_quadrant(obj_lava);
	}
	until (lava_at_quadrant[0] && lava_at_quadrant[1] && lava_at_quadrant[2] && lava_at_quadrant[3]);
}