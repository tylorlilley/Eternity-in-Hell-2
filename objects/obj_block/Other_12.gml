/// @description End Step
event_inherited();

if (just_killed > 1) {
	increment_run_stat("double_block_kill_count");
}
just_killed = 0