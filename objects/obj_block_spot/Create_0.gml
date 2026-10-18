// Spawn a plain block. Map generation randomly determines how many of the room's blocks come alive. Building the room
// turns that many random ones into living blocks, and sometimes hides bones or an item under a block
spawned_block = instance_create(x, y, obj_block);
spawned_block.creator = id;
