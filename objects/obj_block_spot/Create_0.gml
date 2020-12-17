// Sometimes spawn something under block
if get_random_chance_out_of(32) {
	var item = noone;
	switch irandom(10) {
		case 0: { item = obj_sword; break; }
		case 1: { item = obj_torch; break; }
		case 2: { item = obj_key; break; }
		case 3: { item = obj_lantern; break; }
		case 4: { item = obj_map; break; }
		case 5: { item = obj_blood; break; }
		default: { item = obj_bones; break; }
	}
	instance_create_depth(x, y, 4, item);
}

block = instance_create_depth(x, y, -5, obj_block);
block.starting_spot = self;