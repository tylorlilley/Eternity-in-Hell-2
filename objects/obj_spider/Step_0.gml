visible = lethal

if lethal {
    if (!attacking && !global.player.dead) {
        if (global.player.x == x) {
            if (global.player.y > y) { dir = 2; }
            else { dir = 0; }
            attacking = true;
        }
        else if (global.player.y == y) {
            if (global.player.x > x) { dir = 1; }
            else { dir = 3; }
            attacking = true;
        }
    }
    
    if (attacking && obj_game_object_can_move_in_direction(dir, false)) { 
        if !screeched {
            sound_play(snd_lose); 
            screeched = 1; 
        }
        else if screeched < 4 {
            screeched += 1;
        }
        else {
            if (obj_game_object_can_move_in_direction(dir, false)) { obj_game_object_move_in_direction(dir); }
            if (obj_game_object_can_move_in_direction(dir, false)) { obj_game_object_move_in_direction(dir); }
            if (global.controller.number_of_frames_since_game_began mod 2 == 0) { image_xscale *= -1; }
        }
    }
    else { attacking = false; screeched = 0; }
    
    event_inherited();
}

