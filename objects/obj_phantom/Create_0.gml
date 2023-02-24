event_inherited();

var player = global.player, controller = global.controller;
x = player.x;
y = player.y;

activated = false;
corporeal = false;

spawn_timer = 0;

if (controller.current_room.lit) { instance_destroy(); }
else if (controller.entered_from_spawn) { spawn_timer = -1; }
else {
	// Check distance to each unlit lantern
	var lantern_count = 0, total_distance_to_lanterns = 0;
	for (var i = 0; i < instance_number(obj_lantern); i++) {
		var lantern = instance_find(obj_lantern, i);
		
		if (is_existing_instance(lantern) && is_existing_instance(lantern.light_source)) { continue; }
		
		lantern_count += 1;
		total_distance_to_lanterns += get_distance_to_instance(lantern) / 8.0;
	}
	
	if (lantern_count == 0) { instance_destroy(); }
	else {
		// Set spawn timer based on distance to each lantern
		play_sound(snd_dread, false);
		spawn_timer = ceil(total_distance_to_lanterns) - (global.difficulty*lantern_count)
		if (spawn_timer > 48) { spawn_timer = 48; } 
		if (spawn_timer < 16) { spawn_timer = 16; } 
	}
}