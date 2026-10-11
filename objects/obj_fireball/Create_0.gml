event_inherited();

// The mirror it last bounced off, which it won't bounce off again
reflected_by = noone;

// An invisible lit torch it carries, which lights the area around it and the torches it passes over
torch = initialize_fireball_torch_variables(FIREBALL_LIGHT_RANGE)