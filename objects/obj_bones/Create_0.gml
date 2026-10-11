event_inherited();

depth = BONES_DEPTH;
image_index = irandom(5);

// Whether they rise as a skeleton when the player comes near, whether a bug hides in them (both rolled when the room
// is set up), and whether the player has stepped on them
trap = false;
has_bug = false;
disturbed = false;

flip_sprite_at_random(true);
// Sometimes blood lies here in place of the bones
if (get_random_chance_out_of(BLOOD_REPLACEMENT_PROBABILITY)) { 
	instance_destroy(); 
	instance_create(x, y, obj_blood); 
}