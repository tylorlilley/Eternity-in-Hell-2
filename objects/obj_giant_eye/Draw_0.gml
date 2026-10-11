/// @description Draw pupil
// Its eye parts draw the eye itself (see game_room_start), so only the pupil is drawn here
draw_sprite_ext(pupil_sprite, 0, round(pupil_x), round(pupil_y), 1, 1, 1, image_blend, 1);
