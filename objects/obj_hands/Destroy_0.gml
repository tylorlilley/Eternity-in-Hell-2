with (right_hand_item) { become_dropped(other.id); }

if (is_existing_instance(target_item) && target_item.holder == id) { target_item.holder = noone; }