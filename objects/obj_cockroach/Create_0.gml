event_inherited();
end_target_path();

// Path toward meat or the player around solids and lava, planning the path again after every move
target_path_grid = global.controller.current_room.lava_path_grid;
can_interrupt_target_path = true;

// Wait a few steps after appearing. skeleton_speed sets how rarely it moves (see Step), image_index 1 is its frame for
// a room with light, and made_noise is whether it has made its sound in the dark yet.
spawn_timer = 3+irandom(3);
skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY;
image_index = 1;
made_noise = false;