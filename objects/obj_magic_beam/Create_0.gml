event_inherited();

sprite_index = get_sprite_to_use(spr_magic_beam);

// Carry an invisible torch, so the beam gives off light with the range of lava's glow
torch = initialize_fireball_torch_variables(LAVA_LIGHT_RANGE)
torch.lit = false;