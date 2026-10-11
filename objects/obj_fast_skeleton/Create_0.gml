event_inherited();

// Each step a skeleton moves only if a random number from 0 to skeleton_speed is a direction, so the lower the number,
// the faster the skeleton. Fast skeletons use a lower number than regular ones
skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY;