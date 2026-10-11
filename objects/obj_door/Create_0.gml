event_inherited();

// The sound it makes closing, whether it stays open for good (an opened portcullis), whether a key opens it (not for a
// portcullis), the RoomExit it stands in (-1 for none), and the hidden solid that blocks the way while it's closed
// (noone while open)
close_sound = snd_close;
stuck_open = false;
unlocked_by_key = true;
door_for_exit = -1;
closed = noone;
