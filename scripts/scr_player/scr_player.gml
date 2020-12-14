/// @function								Script used to move the player instance
function move_player(dir) {
	with global.player {
		move_in_direction(dir);
		set_instance_to_same_position(carried_item);
		image_index += 1;
		if (image_index > 1) { image_index = 0; }
	}
}