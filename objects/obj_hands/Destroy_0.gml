with (right_hand_item) { become_dropped(other.id); }

if (target_item != noone && instance_exists(target_item) && target_item.holder == id) { target_item.holder = noone; }