var a1 = array_create(0), a2 = array_create(0);

a1 = [ 4 ]
a2 = [ 1, 2, 3 ]

array_contains(a1, a2);
array_duplicate(a2, a1)
array_copy(a2, 0, a1, 0, array_length(a1))

audio_group_load(audiogroup_default);
timer = 0;
draw_set_color(c_black);