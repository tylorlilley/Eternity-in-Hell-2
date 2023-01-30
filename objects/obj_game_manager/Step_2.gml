sounds_to_play = array_unique(sounds_to_play);
while (array_length(sounds_to_play) > 0) {
	var sound_to_play = array_pop(sounds_to_play);
	audio_play_sound(sound_to_play, 10, false);
}
