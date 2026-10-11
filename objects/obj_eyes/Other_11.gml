/// @description Step

// Count down to the next blink. When it comes, and the eyes aren't inside a solid, they make a loud noise, face the
// player and switch between hidden and activated. Only activated eyes chase the player (see move_player)
if (blink_amount > 0) {
	blink_amount -= 1;
}
else if (blink_amount == 0 && !instance_place(x, y, obj_solid)) {
	blink_amount = irandom_range(12, 32);
	play_sound(snd_eyes, true);
	turn_to_face_player();
	activated = !activated;
}
	
// The eyes show their third frame while they chase the player, and go back to the first once no direction is held
var _game_manager = global.game_manager;
if (!(_game_manager.key_up || 
	_game_manager.key_down || 
	_game_manager.key_left || 
	_game_manager.key_right)) { image_index = 0; }
	
event_inherited();