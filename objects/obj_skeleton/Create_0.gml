event_inherited();
end_target_path();

target_path_grid = global.controller.current_room.lava_grid;
can_interrupt_target_path = true;

spawn_timer = 3+irandom(3);
skeleton_speed = SKELETON_MOVE_FREQUENCY;

if (get_random_chance_out_of(FAST_SKELETON_PROBABILITY)) { skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY; image_index = 1; }