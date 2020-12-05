event_inherited();

obj_game_object_turn_to_face_player();

// Disapear and Reappear based on proximity to the player
if (lethal) {
    if (distance_to_instance(global.player) < 40 && !visible) ||
       (distance_to_instance(global.player) >= 40 && visible) { 
        visible = !visible;
        sound_play(snd_squelch);
    }
}
else { visible = false; }

