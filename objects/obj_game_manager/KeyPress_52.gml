// Test mode only toggles in a run started from the IDE, never in an exported game
if (GM_build_type == "run") { global.is_test_mode = !global.is_test_mode; }