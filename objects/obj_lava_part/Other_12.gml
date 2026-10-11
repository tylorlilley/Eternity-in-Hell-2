/// @description End Step

// Deliberately doesn't run the inherited End Step, which sets the image color for lighting and destroys the instance
// outside the room: the lava tile draws the lava, and its parts never leave the room
