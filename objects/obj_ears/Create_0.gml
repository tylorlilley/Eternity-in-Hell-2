event_inherited();
// Start with no path to follow
end_target_path();

// Ears float, so lava doesn't kill them, and they can move along the room border
floating = true;
can_move_on_border = true;

// Steps until a sleeping ear twitches to its next frame, and a random side to face
sprite_timer = 6;
image_xscale = (get_coin_flip()) ? 1 : -1;

// Ears sleep until a loud sound wakes them and sends them to where it came from. They move once per step, so moved
// records whether they already have
awake = false;
moved = false;
target_x = xstart;
target_y = ystart;

// Ears fly over lava, so their paths only go around solids
target_path_grid = global.controller.current_room.solid_path_grid;
