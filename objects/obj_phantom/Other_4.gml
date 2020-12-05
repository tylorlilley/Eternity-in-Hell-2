event_inherited();

visible = false;
lethal = false;

if (global.controller.entered_from_stairs || global.controller.current_room.lit) { spawn_timer = -1; }
else { sound_play(snd_dread); spawn_timer = instance_number(obj_lantern)*20; }

