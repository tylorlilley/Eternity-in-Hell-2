// Sometimes spawn something under block
if get_random_chance_out_of(BLOCK_ITEM_PROBABILITY) {
	var item_obj = (get_coin_flip()) ? get_random_item_obj(true, true) : obj_bones;
	if (item_obj == obj_meat) { item_obj = obj_bomb; }
	instance_create(x, y, item_obj);
}

instance_create(x, y, (get_random_chance_out_of(LIVING_BLOCK_PROBABILITY)) ? obj_living_block : obj_block);
