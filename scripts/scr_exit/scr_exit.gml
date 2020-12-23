/// @function								unlock_exit();
function unlock_exit() {
	locked = false;
}

/// @function								remove_exit();
function remove_exit() {
	room_1.locked_exits[room_1_dir] = noone;
	room_2.locked_exits[room_2_dir] = noone;
	instance_destroy();
}
