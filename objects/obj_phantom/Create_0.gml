event_inherited();

activated = false;
corporeal = false;
floating = true

spawn_timer = 0;
start_timer = false;

var controller = global.controller;
if (controller.current_room.lit) { instance_destroy(); }
else if (controller.entered_from_dir == directions.respawn) { spawn_timer = -1; }