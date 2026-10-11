// Drop what it carries
put_down_item(right_hand_item, false, true);
// Let go of the item it laid down and claimed when the player left the room (see game_room_end)
if (is_existing_instance(target_item) && target_item.holder == id) { target_item.holder = noone; }