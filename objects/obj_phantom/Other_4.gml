event_inherited();

visible = false;
lethal = false;


if (global.controller.current_room.lit) { instance_destroy(); }
else if (global.controller.entered_from_stairs) { spawn_timer = -1; }
else { audio_play_sound( snd_dread, 10, false ); spawn_timer = 15*instance_number(obj_lantern); }

