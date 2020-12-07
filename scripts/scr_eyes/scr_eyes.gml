/// @function  							obj_eyes_teleport_near_player();
function obj_eyes_teleport_near_player() {
	audio_play_sound( snd_flicker, 10, false );

	do {
	    var x_pos = (8*irandom(4));
	    var y_pos = (8*irandom(4));
	    if (irandom(1) == 0) { x_pos *= -1; }
	    if (irandom(1) == 0) { y_pos *= -1; }
	    x = global.player.x + x_pos;
	    y = global.player.y + y_pos;
	}
	until (distance_to_instance(global.player) >= 24 && y >= 0 && y <= room_height && x >= 0 && x <= room_width);
}
