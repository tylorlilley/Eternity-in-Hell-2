/// @description  opposite_dir(dir)
function opposite_dir(argument0) {
	var dir = argument0;

	if (dir < 0 || dir > 3) { return -1; }
	else { return (dir+2) mod 4; }



}
