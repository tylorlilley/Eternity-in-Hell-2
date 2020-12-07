event_inherited();

visible = false;
lethal = false;

if (global.controller.entered_from_stairs || global.controller.current_room.lit) { spawn_timer = -1; }
else { audio_play_sound( snd_dread, 10, false ); spawn_timer = instance_number(obj_lantern)*20; }

