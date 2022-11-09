blink = !blink

var prev_difficulty = global.difficulty;
if (global.difficulty > difficulties.easy && keyboard_check_pressed(vk_left)) { global.difficulty -= 1; }
else if (global.difficulty < difficulties.very_hard && keyboard_check_pressed(vk_right)) { global.difficulty += 1; }
if (prev_difficulty != global.difficulty) {
	var difficulty_sound = noone;
	switch (global.difficulty) {
		case difficulties.easy: { difficulty_sound = snd_pickup; break; }
		case difficulties.medium: { difficulty_sound = snd_putdown; break; }
		case difficulties.hard: { difficulty_sound = snd_skeletonrise; break; }
		case difficulties.very_hard: { difficulty_sound = snd_lose; break; }
	}
	if (difficulty_sound) { play_sound(difficulty_sound, false); }
}