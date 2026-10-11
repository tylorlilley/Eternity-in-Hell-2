/// @description Step
event_inherited();
	
// Turn the sprite, which points up unturned, to point the way the fireball travels. The torch's collision box stays at
// half size
image_xscale = 1;
image_angle = direction+270;
if (is_existing_instance(torch)) { torch.image_xscale = 0.5; }