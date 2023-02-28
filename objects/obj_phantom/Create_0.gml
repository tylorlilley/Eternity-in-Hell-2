event_inherited();

activated = false;
corporeal = false;
floating = true

spawn_timer = 0;

var controller = global.controller;
if (controller.current_room.lit) { instance_destroy(); }
else if (controller.entered_from_spawn) { spawn_timer = -1; }