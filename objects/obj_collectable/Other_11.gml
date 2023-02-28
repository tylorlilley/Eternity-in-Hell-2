/// @description Step
visible = !is_blink_frame();

if (is_instance_at_coordinates(x, y, global.player)) {
	if (instance_number(obj_collectable) == 1) {
	    // You are collecting the final collectable in the room
		play_sound(snd_mana2, true);
		with global.controller {
			current_room.has_collectables = false;
			array_remove(rooms_with_collectables, current_room);
			if (are_all_collectables_collected()) {
				screen_flash();
				play_sound(snd_shatter, false); 
				completion_amount += 1;
			}
		}
	}
	else { play_sound(snd_mana, true); }
	instance_destroy();
}

// If this is a moving collectable, choose a random direction and move in that 
// direction or its opposite if the opposite is away from the player
if moving { run_away_from_player(false, false, true); }

event_inherited();

