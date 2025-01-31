while (array_length(eye_parts) > 0) {
	var eye_part = array_pop(eye_parts);
	with (eye_part) { instance_destroy(); }
}