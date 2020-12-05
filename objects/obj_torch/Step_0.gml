if (time_to_remain_lit > 0) { time_to_remain_lit -= 1/room_speed; }
else if (!time_to_remain_lit && image_speed > 0) {
    // Put out torch
    sound_play(snd_extinguish);
    image_speed = 0;
    image_index = 1;
    with light_source { instance_destroy(); }
}

obj_game_object_set_instance_to_same_position(light_source);

event_inherited();

