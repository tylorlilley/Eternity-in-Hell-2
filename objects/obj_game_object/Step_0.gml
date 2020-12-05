obj_game_object_calculate_lighting(1);
if  (self.id != global.player.id && 
    (x < 0 || x > room_width || y < 0 || y > room_height)) { 
    instance_destroy(); 
}

