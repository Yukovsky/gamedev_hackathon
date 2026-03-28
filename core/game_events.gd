extends Node

# Signal Bus for global events
signal garbage_clicked(amount)
signal metal_collected(amount)
signal resource_changed(type, new_total, limit)
signal build_requested(module_type, grid_pos)
signal ship_updated()
signal metal_limit_updated(new_limit)
