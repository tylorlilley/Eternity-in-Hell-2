/// @function								game_has_been_lost();
function game_has_been_lost() {
	return (floor(global.controller.points) <= 0);
}
