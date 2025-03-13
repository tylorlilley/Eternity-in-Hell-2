/// @description End Step
event_inherited();

if (just_killed > 1) {
	global.controller.evaluation_manager.increment_evaluation_variable("double_block_kill_count");
}
just_killed = 0