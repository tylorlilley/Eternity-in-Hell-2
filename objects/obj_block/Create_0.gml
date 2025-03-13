event_inherited();

depth = PUSH_BLOCK_DEPTH;
sprite_index = get_sprite_to_use(spr_block);
just_pushed = false;
just_killed = 0;

rotate_sprite_to_random_angle();
flip_sprite_at_random(true);
