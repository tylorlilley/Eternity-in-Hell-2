// Sometimes spawn something under block
if get_random_chance_out_of(global.controller.BLOCK_ITEM_PROBABILITY) {
	var item_type = (get_coin_flip()) ? get_random_item_type(true, true) : obj_bones;
	if (item_type == obj_meat) { item_type = obj_bones; }
	instance_create(x, y, item_type);
}

block = instance_create(x, y, obj_block);
block.starting_spot = id;
