if (process_this_frame()) {
	event_inherited();

	if (trap && distance_to_instance(global.player) <= global.controller.TRAP_RANGE) { 
	    play_sound(snd_skeletonrise, true);
	    var skeleton = instance_create_depth(x, y, 0, obj_skeleton);
		skeleton.image_xscale = image_xscale;
	    skeleton.spawn_timer += 6;
		skeleton.usurped = false;
	    instance_destroy();
	}
}
