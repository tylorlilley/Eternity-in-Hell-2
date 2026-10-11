event_inherited();
// Start with no path to follow
end_target_path();

// Eyes make their sound when they're created
play_sound(snd_eyes, false);

// They start hidden and blink in and out (see Step), and they can move along the room border
activated = false;
can_move_on_border = true;

// Steps until the first blink, and a path grid that has their paths go around lava as well as solids
blink_amount = irandom_range(10, 16);
target_path_grid = global.controller.current_room.lava_path_grid;