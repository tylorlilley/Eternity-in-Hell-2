/// @description Step
event_inherited();

// Trap bones rise as a skeleton when the player comes within range, facing the same way and taking a few extra steps
// to rise. Other bones count the first time the player steps on them, for the evaluation.
if (trap && get_distance_to_instance(global.player) <= TRAP_RANGE) { 
	play_sound(snd_skeletonrise, true);
	var _skeleton = instance_create(x, y, obj_skeleton);
	_skeleton.image_xscale = image_xscale;
	_skeleton.spawn_timer += 6;
	instance_destroy();
}
else if (!disturbed && global.player.x == x && global.player.y == y) {
	disturbed = true;
	global.controller.evaluation_manager.increment_evaluation_variable("disturbed_bones");
}
