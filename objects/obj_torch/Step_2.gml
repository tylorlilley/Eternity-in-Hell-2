if (is_existing_instance(light_source)) {
	light_source.persistent = persistent;
	set_instance_to_same_position(light_source);
}