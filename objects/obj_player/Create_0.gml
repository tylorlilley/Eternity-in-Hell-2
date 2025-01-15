event_inherited();
global.player = id;

depth = PLAYER_DEPTH;

right_hand_item = noone;
left_hand_item = noone;

dir = directions.none;
dir_prev = directions.none;
moved_by = noone;
dead = false;
pause_movement = 0;
infected_timer = 0;
bug_image_index = 0;
image_index = 1;

// Create Player Light Source
light = instance_create(x, y, obj_light_source);
light.lighting_range = PLAYER_LIGHT_RANGE;
light.is_flickering_light_source = false;
light.persistent = true;

// Create Player Outline
outline = (global.player_outline) ? instance_create(x, y, obj_outline) : noone;

// Create initial carried torch
with create_item_in_hand(directions.left, obj_torch) { }//light_torch(noone, true); };
with create_item_in_hand(directions.right, obj_staff) { make_item_special(); }


