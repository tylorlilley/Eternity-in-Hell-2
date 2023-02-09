event_inherited();

depth = BONES_DEPTH;
image_index = irandom(5);

trap = false;
has_bug = false;

flip_sprite_at_random(true);
if (get_random_chance_out_of(BLOOD_REPLACEMENT_PROBABILITY)) { 
	instance_destroy(); 
	instance_create(x, y, obj_blood); 
}