// Sometimes spawn something under block
if get_random_chance_out_of(BLOCK_ITEM_PROBABILITY) {
	var item_obj = (get_coin_flip()) ? get_random_item_obj(true, true) : obj_bones;
	if (item_obj == obj_meat) { item_obj = obj_bomb; }
	instance_create(x, y, item_obj);
}

// Spawn a plain block. Map generation rolls how many come alive, and game_room_initialize turns that many random ones into living blocks
spawned_block = instance_create(x, y, obj_block);
spawned_block.creator = id;
