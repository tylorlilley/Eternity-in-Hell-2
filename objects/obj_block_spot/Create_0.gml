// Sometimes spawn something under block
if get_random_chance_out_of(32) {
	var item = (get_random_chance_out_of(2)) ? get_random_item_type() : obj_bones;
	if (item == obj_meat) { item = obj_key; }
	instance_create_depth(x, y, 4, item);
}

block = instance_create_depth(x, y, -5, obj_block);
block.starting_spot = self;
