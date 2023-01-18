event_inherited();
set_farm_mode_sprite(spr_skeleton_farmer);

spawn_timer = 3+irandom(3);
skeleton_speed = 12;

// Create red eyed skeleton
if (get_random_chance_out_of(global.controller.FAST_SKELETON_PROBABILITY)) {
	skeleton_speed = 12;
	image_speed = 1;
}