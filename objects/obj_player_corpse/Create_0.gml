event_inherited();

depth = 4;
image_index = 2;
sprite_index = get_sprite_to_use(spr_player);

has_bug = false;
headless = false;

flip_sprite_at_random(false);

if (is_covered_at_each_quadrant_by(obj_solid)) { instance_destroy(); }