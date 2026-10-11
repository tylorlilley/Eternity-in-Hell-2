event_inherited();
global.player = id;

depth = PLAYER_DEPTH;

// The item held in each hand, and whether the player has lost that hand (a red chest can take one)
right_hand_item = noone;
lost_right_hand = false;
left_hand_item = noone;
lost_left_hand = false;

dir = directions.none;							// The direction the player is pressing this step
dir_prev = directions.none;						// Last step's direction (a random cardinal one if there was none)
moved_by = noone;								// What moved the player this input frame, so they move once per frame at most
dead = false;
pause_movement = 0;								// Steps left before the player can move again after entering a room
infected_timer = 0;								// Moves left while a red bug's infection scrambles the player's inputs
bug_image_index = 0;							// Animation frame of the red bug drawn on an infected player
bug_sound_timer = 0;							// Steps until the red bug's next sound
image_index = 1;

// Create Player Light Source
light = instance_create(x, y, obj_light_source);
light.lighting_range = PLAYER_LIGHT_RANGE;
light.is_flickering_light_source = false;
light.persistent = true;

// Create Player Outline
outline = (global.player_outline) ? instance_create(x, y, obj_outline) : noone;

// Put the starting items chosen on the title screen in the player's hands, lighting a torch right away
if (global.player_left_hand_item != noone) {
	with create_item_in_hand(directions.left, global.player_left_hand_item) { 
		if (object_index == obj_torch) { light_torch(noone, true); }
	}
}
if (global.player_right_hand_item != noone) {
	with create_item_in_hand(directions.right, global.player_right_hand_item) {
		if (object_index == obj_torch) { light_torch(noone, true); }
	}
}
