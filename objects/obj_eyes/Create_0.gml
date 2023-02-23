event_inherited();
end_target_path();

play_sound(snd_eyes, false);

activated = false;
can_move_on_border = true;

blink_amount = irandom_range(10, 16);
target_path_grid = global.controller.current_room.lava_grid;