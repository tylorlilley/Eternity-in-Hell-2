event_inherited();

if (trap && distance_to_instance(global.player) <= 32) { 
    sound_play(snd_skeletonrise);
    var skeleton = instance_create_depth(x, y, 0, obj_skeleton);
    skeleton.spawn_timer += 3;
    instance_destroy();
}

