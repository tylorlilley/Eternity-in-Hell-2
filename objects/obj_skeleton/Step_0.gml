if (spawn_timer > 0) { spawn_timer -= 1; }
else { var dir = irandom(skeleton_speed); if (obj_game_object_can_move_in_direction(dir, false)) { obj_game_object_move_in_direction(dir); } }

event_inherited();

