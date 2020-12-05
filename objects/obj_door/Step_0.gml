event_inherited();

if closed {
    if locked image_index = 2;
    if ((dir == 0 || dir == 2) && 
       ((instance_at_coordinates(global.player.x_prev, global.player.y_prev-16, self) && keyboard_check_pressed(vk_up))) ||
       ((instance_at_coordinates(global.player.x_prev, global.player.y_prev+16, self) && keyboard_check_pressed(vk_down)))) || 
       ((dir == 1 || dir == 3) && 
       ((instance_at_coordinates(global.player.x_prev-16, global.player.y_prev, self) && keyboard_check_pressed(vk_left))) ||
       ((instance_at_coordinates(global.player.x_prev+16, global.player.y_prev, self) && keyboard_check_pressed(vk_right)))) ||
       instance_place(x, y, obj_player) {
           if (locked && global.controller.collected_keys <= 0) { sound_play(snd_locked); }
           else { obj_door_open(); }
    }
}


