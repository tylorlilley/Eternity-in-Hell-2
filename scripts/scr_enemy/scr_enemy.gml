/// @function								kill_enemy();
function kill_enemy() {
	instance_destroy();
	audio_play_sound(death_sound, 10, false);
}