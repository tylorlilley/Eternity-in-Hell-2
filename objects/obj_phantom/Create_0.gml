event_inherited();
set_farm_mode_sprite(spr_phantom_farmer);

x = global.player.x;
y = global.player.y;

activated = false;
corporeal = false;

spawn_timer = (global.controller.entered_from_stairs) ? 12 : 0;

if (global.controller.current_room.lit) { instance_destroy(); }
else if (global.controller.entered_from_spawn) { spawn_timer = -1; }
else {
	play_sound(snd_dread, false); 
	with (obj_lantern) { if (!instance_exists(light_source)) { other.spawn_timer += (16 - global.difficulty); } }
	if (spawn_timer > 50) { spawn_timer = 60; } 
	if (spawn_timer < 15) { spawn_timer = 15; } 
}