if (can_process_this_frame()) {
	event_inherited();

	if (trap && get_distance_to_instance(global.player) <= global.controller.TRAP_RANGE) { 
	    play_sound(snd_skeletonrise, true);
	    var skeleton = instance_create(x, y, obj_skeleton);
		skeleton.image_xscale = image_xscale;
	    skeleton.spawn_timer += 6;
	    instance_destroy();
	}
}
