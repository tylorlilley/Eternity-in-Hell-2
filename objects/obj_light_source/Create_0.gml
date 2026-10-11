event_inherited();

// The most and least of its light that reaches an instance, before it's scaled by its intensity (see
// get_relative_light_intensity)
maximum_intensity = 1;
minimum_intensity = 0;

// How far it reaches in dimming steps, and the distance it lights right now, which flickers around that range
lighting_range = 0;
lighting_distance = 0;

// Whether its distance flickers, and by how much right now
is_flickering_light_source = true;
flicker = 0;

// Scales all of its light
intensity = 1;
