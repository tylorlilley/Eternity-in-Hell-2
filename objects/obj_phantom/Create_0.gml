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
	var lantern_count = 0, total_distance_to_lanterns = 0, steps_to_reach_lanterns = 0;
	for (var i = 0; i < instance_number(obj_lantern); i++) {
		var lantern = instance_find(obj_lantern, i);
		
		if (lantern.light_source == noone) { continue; }
		
		lantern_count += 1;
		total_distance_to_lanterns += point_distance(x, y, lantern.x, lantern.y) / 8.0;
	}
	
	if (lantern_count == 0) { instance_destroy(); }
	else {
		// Set spawn timer based on distance to each lantern
		play_sound(snd_dread, false);
		steps_to_reach_lanterns = total_distance_to_lanterns/lantern_count;
		spawn_timer = floor(steps_to_reach_lanterns * (6-global.difficulty)/2);
		if (spawn_timer > 60) { spawn_timer = 60; } 
		if (spawn_timer < 12) { spawn_timer = 12; } 
	
		show_debug_message(room_get_name(global.controller.current_room.room_reference) + ": " + string(spawn_timer));
	}
}