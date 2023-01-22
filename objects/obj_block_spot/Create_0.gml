// Sometimes spawn something under block
if get_random_chance_out_of(global.controller.BLOCK_ITEM_PROBABILITY) {
	var item = (get_coin_flip()) ? get_random_item_type(true) : obj_bones;
	if (item != obj_meat) { item = obj_bones; }
	instance_create(x, y, item);
}

block = instance_create(x, y, obj_block);
block.starting_spot = id;
