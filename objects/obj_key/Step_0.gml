if (process_this_frame()) {
	event_inherited();

	if (instance_at_coordinates(x, y, global.player)) {
	    global.controller.current_room.has_key = false;
	    global.controller.collected_keys += 1;
	    instance_destroy();
	    audio_play_sound( snd_mana, 10, false );
	}
}
