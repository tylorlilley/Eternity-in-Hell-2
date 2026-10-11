event_inherited();

// How far its sprite is drawn above or below the hand while carried, which depends on the sprite
draw_y_offset = get_carried_item_draw_y_offset(sprite_index);
can_pick_up = true;
special = false;
// Who carries it, or noone while it lies on the ground
holder = noone;
// Whether it has been counted among the special items the player used
counted = false;
// When it was created or last put down, so the player picks up dropped items oldest first
last_held = date_current_datetime();

// A clock's sand or a compass's hands are a second sprite drawn over the item
time_image_index = 0;
time_sprite_index = noone;
// Times the fire animation of a lit torch, and is -1 while the torch is out
torch_light_image_timer = -1;