if (process_this_frame()) {
	event_inherited();

	if (trap && distance_to_instance(global.player) <= 40) { 
	    audio_play_sound( snd_skeletonrise, 10, false );
	    var skeleton = instance_create_depth(x, y, 0, obj_skeleton);
		skeleton.image_xscale = image_xscale;
	    skeleton.spawn_timer += 6;
	    instance_destroy();
	}
}
