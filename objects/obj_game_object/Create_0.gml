// Sprites don't animate on their own, and start in the background color, as if unlit (see End Step)
image_speed = 0;
image_blend = global.bg_color;

// Use the version of the sprite that the current graphics mode calls for
sprite_index = get_sprite_to_use(sprite_index);