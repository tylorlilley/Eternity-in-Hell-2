event_inherited();
end_target_path();

// Lies dormant until the player comes within trap range, or meat is dropped
activated = false;

right_hand_item = noone;
left_hand_item = noone; // Hands never use it, but the item functions they share with the player expect it
// The item it's going for, starting with the one it spawns on (see game_room_start_spawn_instances)
target_item = noone;
// Counts down while hands revived by a rosary wait to come back (see kill_enemy)
death_timer = 0;

// Find paths around lava as well as solids, and plan the path again after each move
target_path_grid = global.controller.current_room.lava_path_grid;
can_interrupt_target_path = true;