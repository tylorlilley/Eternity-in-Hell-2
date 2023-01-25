event_inherited();

x = global.player.x;
y = global.player.y;

activated = false;
corporeal = false;

spawn_timer = 0;

if (global.controller.current_room.lit) { instance_destroy(); }
else if (global.controller.entered_from_spawn) { spawn_timer = -1; }
else {
	// Check distance to each unlit lantern
	var lantern_count = 0, total_distance_to_lanterns = 0;
	for (var i = 0; i < instance_number(obj_lantern); i++) {
		var lantern = instance_find(obj_lantern, i);
		
		if (lantern.light_source != noone) { continue; }
		
		lantern_count += 1;
		total_distance_to_lanterns += point_distance(x, y, lantern.x, lantern.y) / 8.0;
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