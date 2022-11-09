// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs,
	respawn
}

// global variables to represent the various game difficulty settings
enum difficulties {
	DO_NOT_USE,
	easy,
	medium,
	hard,
	very_hard
}

global.difficulty = difficulties.medium;