/// @description End Step
// While inactive, it only updates its color for the lighting, skipping the check that destroys it outside the room
if (activated) { event_inherited(); }
else if (can_process_this_frame()) { image_blend = get_image_blend(); }

