event_inherited();

sprite_index = get_sprite_to_use(spr_magic_beam);

// Torch Variables
torch = initialize_fireball_torch_variables(LAVA_LIGHT_RANGE)
torch.lit = false;