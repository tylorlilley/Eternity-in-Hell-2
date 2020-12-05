if (instance_at_coordinates(x, y, global.player)) {
    if (instance_number(obj_collectable) == 1) {
        // You are collecting the final collectable in the room
        global.controller.current_room.collectables_collected = true;
        global.controller.rooms_with_collectables_collected += 1;
        if (game_has_been_won()) { sound_play(snd_win); }
    }
    instance_destroy();
    sound_play(snd_mana);
}

// If this is a moving collectable, choose a random direction and move in that 
// direction or its opposite if the opposite is away from the player
if moving { 
    var dir = irandom(3);
    if (obj_game_object_is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
    if (irandom(2) == 0) { dir = 4; }
    if (obj_game_object_can_move_in_direction(dir, false)) { obj_game_object_move_in_direction(dir); }
}

event_inherited();

