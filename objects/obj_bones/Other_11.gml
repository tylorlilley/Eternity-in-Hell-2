/// @description Step
event_inherited();

if (trap && get_distance_to_instance(global.player) <= TRAP_RANGE) { 
	play_sound(snd_skeletonrise, true);
	var skeleton = instance_create(x, y, obj_skeleton);
	skeleton.image_xscale = image_xscale;
	skeleton.spawn_timer += 6;
	instance_destroy();
}
else if (!disturbed && global.player.x = x && global.player.y = y) {
	disturbed = true;
	global.controller.evaluation_manager.increment_evaluation_variable("disturbed_bones");
}
