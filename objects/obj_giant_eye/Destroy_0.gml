// Destroy its eye parts along with it
while (array_length(eye_parts) > 0) {
	var _eye_part = array_pop(eye_parts);
	with (_eye_part) { instance_destroy(); }
}