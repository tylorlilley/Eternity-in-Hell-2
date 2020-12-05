if (spawn_timer > 0) { spawn_timer -= 1;  }
else if (spawn_timer == 0) {
    // Move in a random direction, and turn toward player if that direction is away from player.
    var dir = irandom(4);
    if (!obj_game_object_is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
    if (obj_game_object_can_move_in_direction(dir, true)) { obj_game_object_move_in_direction(dir); }
    
    if (irandom(2) == 0) { visible = true; sound_play(snd_flicker); }
    else { visible = false; }
    
    if (!lethal) { 
        sound_play(snd_static); 
        lethal = true;
    }
}

if (global.controller.current_room.lit) { instance_destroy(); sound_play(snd_impact); }

event_inherited();

