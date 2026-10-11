event_inherited();

image_speed = 0;
infectious = false;

// A bug that comes out on the player, in lava or in a solid dies at once. Otherwise it is sometimes a red bug, which
// infects the player when it dies next to them.
if (get_distance_to_instance(global.player) <= 4 ||
	place_meeting(x, y, obj_death) ||
	place_meeting(x, y, obj_solid)) {
		instance_destroy();
}
else if (get_random_chance_out_of(RED_BUG_PROBABILITY)) {
	sprite_index = spr_bug_red;
	infectious = true;
}
