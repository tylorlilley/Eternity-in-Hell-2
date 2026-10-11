/// @description End Step
event_inherited();

// Count a push that crushed two or more enemies at once, then reset the count for the next step
if (just_killed > 1) {
	global.controller.evaluation_manager.increment_evaluation_variable("double_block_kill_count");
}
just_killed = 0