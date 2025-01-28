event_inherited();

contents_obj = -1;
remains_obj = obj_blood;
contents_is_special = true;
hand_remover = true;
closed = false;
locked = false;
image_index = 1;

// Create Surrounding Blood
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);
instance_create(x-48+(8*irandom(12)), y-48+(8*irandom(12)), obj_blood);