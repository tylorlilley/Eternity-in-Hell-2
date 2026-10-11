event_inherited();

// Lava and fireballs don't kill it, and it walks through lava. It moves as often as a regular skeleton does
fire_resistant = true;
skeleton_speed = SKELETON_MOVE_FREQUENCY;

// Steps until it first shoots a fireball
shoot_timer = irandom_range(24, 48);

// In Step it calls the fireball functions, which read the variables of a projectile. It counts as having created
// itself, and as not shot by the player
prev_speed = 0;
creator = id;
creator_obj = -1;
destructive = false;
shot_by_player = false;
consume_block = true;
torch = noone;

// Glow like lava
initialize_lava_lighting();

// The sprite, frame and frame timer of its torch light, which Draw puts behind it
torch_light_image_timer = 0;
torch_light_sprite_index = spr_torch_light;
torch_light_image_index = 0;