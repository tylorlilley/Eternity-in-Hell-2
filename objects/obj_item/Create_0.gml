event_inherited();

draw_y_offset = get_carried_item_draw_y_offset(sprite_index);
can_pick_up = true;
special = false;
holder = noone;
counted = false;
last_held = date_current_datetime();

time_image_index = 0;
time_sprite_index = noone;
torch_light_image_timer = -1;