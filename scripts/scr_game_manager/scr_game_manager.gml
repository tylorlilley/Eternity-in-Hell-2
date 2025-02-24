/// @function								set_up_inputs_for_next_frame();
function set_up_inputs_for_next_frame() {
	if (instance_number(obj_title) > 0) { 
		get_keyboard_default_inputs();
		if (global.input == inputs.keyboard_wasd) { get_keyboard_wasd_inputs(); }
		get_gamepad_inputs();
	}
	else {
		switch (global.input) {
			case inputs.keyboard_default: { get_keyboard_default_inputs(); break; }
			case inputs.keyboard_wasd: { get_keyboard_wasd_inputs(); break; }
			case inputs.gamepad: { get_gamepad_inputs(); break; }
		}
	}
	
	if (is_existing_instance(global.player) && !global.player.dead && global.player.infected_timer > 0 && !paused) { get_random_inputs(); }
}

/// @function								get_random_inputs();
function get_random_inputs() {
	key_up_pressed = get_random_chance_out_of((prev_key_up) ? 4 : 12);
	key_down_pressed = get_random_chance_out_of((prev_key_down) ? 4 : 12);
	key_left_pressed = get_random_chance_out_of((prev_key_left) ? 4 : 12);
	key_right_pressed = get_random_chance_out_of((prev_key_right) ? 4 : 12);
	key_z_pressed = get_random_chance_out_of(32);
	key_x_pressed = get_random_chance_out_of(32);
	
	key_up_released = !key_up_pressed && get_random_chance_out_of(4);
	key_down_released = !key_down_released && get_random_chance_out_of(4);
	key_left_released = !key_left_released && get_random_chance_out_of(4);
	key_right_released = !key_right_released && get_random_chance_out_of(4);
	
	key_up = !key_up_released && (key_up_pressed || prev_key_up);
	key_down = !key_down_released && (key_down_pressed || prev_key_down);
	key_left = !key_left_released && (key_left_pressed || prev_key_left);
	key_right = !key_right_released && (key_right_pressed || prev_key_right);
}

/// @function								clear_inputs_for_next_frame();
function clear_inputs_for_next_frame() {
	prev_key_up = key_up;
	prev_key_down = key_down;
	prev_key_left = key_left;
	prev_key_right = key_right;

	key_up = false;
	key_down = false;
	key_left = false;
	key_right = false;
	key_space = false;
	key_enter = false;
	key_z = false;
	key_x = false;
	
	key_up_pressed = false;
	key_down_pressed = false;
	key_left_pressed = false;
	key_right_pressed = false;
	key_space_pressed = false;
	key_enter_pressed = false;
	key_z_pressed = false;
	key_x_pressed = false;
	
	key_up_released = false;
	key_down_released = false;
	key_left_released = false;
	key_right_released = false;
	key_space_released = false;
	key_enter_released = false;
	key_z_released = false;
	key_x_released = false;
	key_esc_released = false;
}

/// @function								get_keyboard_default_inputs();
function get_keyboard_default_inputs() {
	key_up = key_up || keyboard_check(vk_up);
	key_down = key_down || keyboard_check(vk_down);
	key_left = key_left || keyboard_check(vk_left);
	key_right = key_right || keyboard_check(vk_right);
	key_space = key_space|| keyboard_check(vk_space);
	key_enter = key_enter|| keyboard_check(vk_enter);
	key_z = key_z || keyboard_check(ord("Z"));
	key_x = key_x || keyboard_check(ord("X"));
	
	key_up_pressed = key_up_pressed || keyboard_check_pressed(vk_up);
	key_down_pressed = key_down_pressed || keyboard_check_pressed(vk_down);
	key_left_pressed = key_left_pressed || keyboard_check_pressed(vk_left);
	key_right_pressed = key_right_pressed || keyboard_check_pressed(vk_right);
	key_space_pressed = key_space_pressed || keyboard_check_pressed(vk_space);
	key_enter_pressed = key_enter_pressed || keyboard_check_pressed(vk_enter);
	key_z_pressed  = key_z_pressed || keyboard_check_pressed (ord("Z"));
	key_x_pressed  = key_x_pressed || keyboard_check_pressed (ord("X"));
	
	key_up_released = key_up_released || keyboard_check_released(vk_up);
	key_down_released = key_down_released || keyboard_check_released(vk_down);
	key_left_released = key_left_released || keyboard_check_released(vk_left);
	key_right_released = key_right_released || keyboard_check_released(vk_right);	
	key_space_released = key_space_released || keyboard_check_released(vk_space);
	key_enter_released = key_enter_released || keyboard_check_released(vk_enter);
	key_z_released = key_z_released || keyboard_check_released(ord("Z"));
	key_x_released = key_x_released || keyboard_check_released(ord("X"));
	key_esc_released = key_esc_released || keyboard_check_released(vk_escape);
}

/// @function								get_keyboard_wasd_inputs();
function get_keyboard_wasd_inputs() {
	key_up = key_up || keyboard_check(ord("W"));
	key_down = key_down || keyboard_check(ord("S"));
	key_left = key_left || keyboard_check(ord("A"));
	key_right = key_right || keyboard_check(ord("D"));
	key_space = key_space|| keyboard_check(vk_space);
	key_enter = key_enter|| keyboard_check(vk_enter);
	key_z = key_z || keyboard_check(ord("J"));
	key_x = key_x || keyboard_check(ord("K"));
	
	key_up_pressed = key_up_pressed || keyboard_check_pressed(ord("W"));
	key_down_pressed = key_down_pressed || keyboard_check_pressed(ord("S"));
	key_left_pressed = key_left_pressed || keyboard_check_pressed(ord("A"));
	key_right_pressed = key_right_pressed || keyboard_check_pressed(ord("D"));
	key_space_pressed = key_space_pressed || keyboard_check_pressed(vk_space);
	key_enter_pressed = key_enter_pressed || keyboard_check_pressed(vk_enter);
	key_z_pressed  = key_z_pressed || keyboard_check_pressed (ord("J"));
	key_x_pressed  = key_x_pressed || keyboard_check_pressed (ord("K"));
	
	key_up_released = key_up_released || keyboard_check_released(ord("W"));
	key_down_released = key_down_released || keyboard_check_released(ord("S"));
	key_left_released = key_left_released || keyboard_check_released(ord("A"));
	key_right_released = key_right_released || keyboard_check_released(ord("D"));	
	key_space_released = key_space_released || keyboard_check_released(vk_space);
	key_enter_released = key_enter_released || keyboard_check_released(vk_enter);
	key_z_released = key_z_released || keyboard_check_released(ord("J"));
	key_x_released = key_x_released || keyboard_check_released(ord("K"));
	key_esc_released = key_esc_released || keyboard_check_released(vk_escape);
}

/// @function								get_gamepad_inputs();
function get_gamepad_inputs() {
	var gamepad = global.gamepad;
	key_up = key_up || gamepad_button_check(gamepad, gp_padu) || gamepad_axis_value(gamepad, gp_axislv) < -0.5;
	key_down = key_down || gamepad_button_check(gamepad, gp_padd) || gamepad_axis_value(gamepad, gp_axislv) > 0.5;
	key_left = key_left || gamepad_button_check(gamepad, gp_padl) || gamepad_axis_value(gamepad, gp_axislh) < -0.5;
	key_right = key_right || gamepad_button_check(gamepad, gp_padr) || gamepad_axis_value(gamepad, gp_axislh) > 0.5;
	key_space = key_space || gamepad_button_check(gamepad, gp_shoulderlb) || gamepad_button_check(gamepad, gp_shoulderrb) || gamepad_button_check(gamepad, gp_face3) || gamepad_button_check(gamepad, gp_face4);
	key_enter = key_enter || gamepad_button_check(gamepad, gp_start) || gamepad_button_check(gamepad, gp_select);
	key_z = key_z || gamepad_button_check(gamepad, gp_face1) || gamepad_button_check(gamepad, gp_shoulderl);
	key_x = key_x || gamepad_button_check(gamepad, gp_face2)  || gamepad_button_check(gamepad, gp_shoulderr);
	
	key_up_pressed = key_up_pressed || gamepad_button_check_pressed(gamepad, gp_padu) || (prev_axislv_value >= -0.5 && gamepad_axis_value(gamepad, gp_axislv) < -0.5);
	key_down_pressed = key_down_pressed || gamepad_button_check_pressed(gamepad, gp_padd) || (prev_axislv_value <= 0.5 && gamepad_axis_value(gamepad, gp_axislv) > 0.5);
	key_left_pressed = key_left_pressed || gamepad_button_check_pressed(gamepad, gp_padl) || (prev_axislh_value >= -0.5 && gamepad_axis_value(gamepad, gp_axislh) < -0.5);
	key_right_pressed = key_right_pressed || gamepad_button_check_pressed(gamepad, gp_padr) || (prev_axislh_value <= 0.5 && gamepad_axis_value(gamepad, gp_axislh) > 0.5);
	key_space_pressed = key_space_pressed || gamepad_button_check_pressed(gamepad, gp_shoulderlb) || gamepad_button_check_pressed(gamepad, gp_shoulderrb) || gamepad_button_check_pressed(gamepad, gp_face3) || gamepad_button_check_pressed(gamepad, gp_face4);
	key_enter_pressed = key_enter_pressed || gamepad_button_check_pressed(gamepad, gp_start) || gamepad_button_check_pressed(gamepad, gp_select)
	key_z_pressed  = key_z_pressed || gamepad_button_check_pressed(gamepad, gp_face1) || gamepad_button_check_pressed(gamepad, gp_shoulderl);
	key_x_pressed  = key_x_pressed || gamepad_button_check_pressed(gamepad, gp_face2) || gamepad_button_check_pressed(gamepad, gp_shoulderr);
	
	key_up_released = key_up_released || gamepad_button_check_released(gamepad, gp_padu);
	key_down_released = key_down_released || gamepad_button_check_released(gamepad, gp_padd);
	key_left_released = key_left_released || gamepad_button_check_released(gamepad, gp_padl);
	key_right_released = key_right_released || gamepad_button_check_released(gamepad, gp_padr);	
	key_space_released = key_space_released ||  gamepad_button_check_released(gamepad, gp_shoulderlb) || gamepad_button_check_released(gamepad, gp_shoulderrb) || gamepad_button_check_released(gamepad, gp_face3) || gamepad_button_check_released(gamepad, gp_face4);
	key_enter_released = key_enter_released || gamepad_button_check_released(gamepad, gp_start) || gamepad_button_check_released(gamepad, gp_select);
	key_z_released = key_z_released || gamepad_button_check_released(gamepad, gp_face1) || gamepad_button_check_released(gamepad, gp_shoulderl);
	key_x_released = key_x_released || gamepad_button_check_released(gamepad, gp_face2) || gamepad_button_check_released(gamepad, gp_shoulderr);
	key_esc_released = key_esc_released || keyboard_check_released(vk_escape);
	
	prev_axislv_value = gamepad_axis_value(gamepad, gp_axislv);
	prev_axislh_value = gamepad_axis_value(gamepad, gp_axislh);
	
}

/// @function								initialize_shader_pointers();
function initialize_shader_pointers() {
	shader_color = shader_get_uniform(sh_eih, "new_color");
	shader_bg_color = shader_get_uniform(sh_eih, "bg_color");
	shader_color_fade = shader_get_uniform(sh_eih, "color_fade");
}

/// @function								set_eih_shader();
function set_eih_shader() {
	shader_set(sh_eih);
	shader_set_uniform_f_array(shader_color, global.game_color);
	shader_set_uniform_f_array(shader_bg_color, get_shader_color_from_gms_color(global.bg_color));
	shader_set_uniform_f(shader_color_fade, global.game_color_fade);
}

/// @function								is_thump_frame();
function is_thump_frame() {
	var thump_timer = (global.game_manager.number_of_frames_since_game_began/FRAMES_TO_WAIT_BEFORE_PROCESSING) % FRAMES_FOR_HEART_THUMP;
	return (thump_timer > 0 && thump_timer <= 3);
}

/// @function								is_blink_frame();
function is_blink_frame() {
	return (global.game_manager.number_of_frames_since_game_began % 24 >= 12);
}


/// @function								return_to_title_screen();
function return_to_title_screen() { 			
	paused = false;
	number_of_frames_since_game_began = 0;
	clear_inputs_for_next_frame();
	with (obj_controller) {
		if (!is_game_won() && !is_game_lost()) { update_log("outcome", "reset"); }
		restart_game(); 
	}
}