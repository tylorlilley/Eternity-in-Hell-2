event_inherited();

// Each step a skeleton moves only if a random number from 0 to skeleton_speed is a direction, so the higher the number,
// the slower the skeleton. Fat skeletons use a higher number than regular ones
skeleton_speed = FAT_SKELETON_MOVE_FREQUENCY;

// Paths go around lava as well as solids, and fat skeletons can move along the room border
target_path_grid = global.controller.current_room.lava_path_grid;
can_move_on_border = true;

// Steps of rage left. The controller sets it while the player looks at the map, and the fat skeleton charges at them
rage_counter = 0;