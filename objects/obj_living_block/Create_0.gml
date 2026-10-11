event_inherited();

// Swap the block's sprite for the living block's, undoing the random turn and vertical flip the block gave it: it is
// only mirrored left to right at random
sprite_index = get_sprite_to_use(spr_living_block);

image_angle = 0;
image_yscale = 1;
image_index = 0;
flip_sprite_at_random(false);

// Steps left until it next moves on its own
move_timer = irandom_range(128,512);
