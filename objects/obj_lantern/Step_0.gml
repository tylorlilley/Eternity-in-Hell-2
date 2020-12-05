event_inherited();

var torch = instance_place(x, y, obj_torch);
if !light_source && torch && torch.light_source {
    obj_lantern_light(false);
}
if light_source && torch {
    with torch {
        if (time_to_remain_lit == 0) { obj_torch_light(); }
        else { time_to_remain_lit = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT; }
    }
}

