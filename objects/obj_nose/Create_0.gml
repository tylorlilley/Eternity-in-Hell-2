event_inherited();
set_farm_mode_sprite(spr_eyes_farmer);
teleport_to_lava();

//image_blend = global.controller.bg_color;

activated = false;
fire_resistant = true;

spawn_timer = irandom_range(8, 32);
shoot_timer = 0;