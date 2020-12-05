
if (irandom(3) == 0 && (keyboard_check(vk_up) || keyboard_check(vk_down) || keyboard_check(vk_right) || keyboard_check(vk_left))) {
    obj_eyes_teleport_near_player();
}

// Make sprite flicker and infrequently switch to another image
visible = (global.controller.number_of_frames_since_game_began mod 2 == 0);
image_index = (irandom(15) == 0);
obj_game_object_turn_to_face_player();

event_inherited();


