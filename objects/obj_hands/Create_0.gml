event_inherited();
end_target_path();

activated = false;

right_hand_item = noone;
left_hand_item = noone; // not used by this enemy; included to keep parity with player item functions
target_item = noone;
death_timer = 0;

target_path_grid = global.controller.current_room.lava_grid;
can_interrupt_target_path = true;