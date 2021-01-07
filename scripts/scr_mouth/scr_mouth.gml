/// @function								teleport_to_empty_space()
function teleport_to_empty_space() {
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
	}
	until (!instance_place(x, y, obj_solid) && 
			!instance_place(x, y, obj_death) && 
			distance_to_instance(global.player) >= MOUTH_DISTANCE);
}