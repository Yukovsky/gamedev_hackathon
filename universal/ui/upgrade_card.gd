extends Button
class_name UpgradeCard

signal card_pressed(card: UpgradeCard)

enum ActionKind {
	MODULE_BUILD,
	UPGRADE_PURCHASE,
	PLACEHOLDER,
}

const FONT_FILE: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

var action_kind: ActionKind = ActionKind.PLACEHOLDER
var module_id: String = ""
var upgrade_id: String = ""
var _title_text: String = ""
var _description_text: String = ""
var _price_text: String = ""
var _icon_texture: Texture2D
var _accent_color: Color = Color(0.756863, 0.564706, 0.87451, 1.0)
var _available: bool = true
var _is_maxed: bool = false
var _layout_ready: bool = false

var _content_margin: MarginContainer
var _icon_rect: TextureRect
var _text_column: VBoxContainer
var _title_label: Label
var _description_label: Label
var _price_label: Label
var _status_label: Label


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_layout()
	pressed.connect(_on_pressed)
	_apply_visuals()


func configure(
	kind: ActionKind,
	icon_texture: Texture2D,
	title: String,
	description: String,
	price_text: String,
	accent_color: Color,
	available: bool,
	is_maxed: bool,
	module: String = "",
	upgrade: String = ""
) -> void:
	action_kind = kind
	_icon_texture = icon_texture
	_title_text = title
	_description_text = description
	_price_text = price_text
	_accent_color = accent_color
	_available = available
	_is_maxed = is_maxed
	module_id = module
	upgrade_id = upgrade
	if _layout_ready:
		_apply_visuals()


func set_price_text(price_text: String) -> void:
	_price_text = price_text
	if _layout_ready:
		_apply_visuals()


func set_available(value: bool) -> void:
	_available = value
	if _layout_ready:
		_apply_visuals()


func set_maxed(value: bool) -> void:
	_is_maxed = value
	if _layout_ready:
		_apply_visuals()


func set_accent_color(value: Color) -> void:
	_accent_color = value
	if _layout_ready:
		_apply_visuals()


func _build_layout() -> void:
	if _layout_ready:
		return

	custom_minimum_size = Vector2(0.0, 186.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flat = true
	toggle_mode = false

	_content_margin = MarginContainer.new()
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_margin.add_theme_constant_override("margin_left", 20)
	_content_margin.add_theme_constant_override("margin_top", 18)
	_content_margin.add_theme_constant_override("margin_right", 18)
	_content_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(_content_margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	_content_margin.add_child(row)

	_icon_rect = TextureRect.new()
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.custom_minimum_size = Vector2(104.0, 104.0)
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_icon_rect)

	_text_column = VBoxContainer.new()
	_text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Keep the list card readable even on small screens.
	_text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_column.add_theme_constant_override("separation", 8)
	row.add_child(_text_column)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.label_settings = _make_label_settings(24, Color.WHITE)
	_text_column.add_child(_title_label)

	_description_label = Label.new()
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_description_label.label_settings = _make_label_settings(16, Color.WHITE)
	_text_column.add_child(_description_label)

	var price_column: VBoxContainer = VBoxContainer.new()
	price_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_column.custom_minimum_size = Vector2(148.0, 0.0)
	price_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	price_column.alignment = BoxContainer.ALIGNMENT_CENTER
	price_column.add_theme_constant_override("separation", 8)
	row.add_child(price_column)

	_status_label = Label.new()
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.label_settings = _make_label_settings(16, Color.WHITE)
	price_column.add_child(_status_label)

	_price_label = Label.new()
	_price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_price_label.label_settings = _make_label_settings(24, Color.WHITE)
	price_column.add_child(_price_label)

	_layout_ready = true


func _apply_visuals() -> void:
	if _icon_rect != null:
		_icon_rect.texture = _icon_texture
	if _title_label != null:
		_title_label.text = _title_text
	if _description_label != null:
		_description_label.text = _description_text
	if _price_label != null:
		_price_label.text = _price_text
	if _status_label != null:
		_status_label.text = "MAX" if _is_maxed else ("ГОТОВО" if _available else "НЕДОСТУПНО")

	var title_color: Color = _accent_color
	var description_color: Color = Color(0.815686, 0.627451, 0.941176, 1.0)
	var price_color: Color = Color(0.941176, 0.815686, 0.12549, 1.0)
	var status_color: Color = Color(0.815686, 0.627451, 0.941176, 1.0)

	if not _available:
		title_color = Color(0.62, 0.54, 0.72, 1.0)
		description_color = Color(0.48, 0.42, 0.55, 1.0)
		price_color = Color(0.78, 0.24, 0.24, 1.0)
		status_color = Color(0.78, 0.24, 0.24, 1.0)
	if _is_maxed:
		price_color = Color(0.56, 0.9, 0.62, 1.0)
		status_color = Color(0.56, 0.9, 0.62, 1.0)

	if _title_label != null:
		_title_label.label_settings = _make_label_settings(24, title_color)
	if _description_label != null:
		_description_label.label_settings = _make_label_settings(16, description_color)
	if _price_label != null:
		_price_label.label_settings = _make_label_settings(24, price_color)
	if _status_label != null:
		_status_label.label_settings = _make_label_settings(16, status_color)

	_update_theme_style()
	disabled = not _available


func _update_theme_style() -> void:
	var normal_style: StyleBoxFlat = _make_style(0.047, 0.019, 0.125, 0.96, _accent_color)
	var hover_style: StyleBoxFlat = _make_style(0.078, 0.035, 0.184, 1.0, _accent_color.lightened(0.1))
	var pressed_style: StyleBoxFlat = _make_style(0.109, 0.058, 0.239, 1.0, _accent_color.lightened(0.18))
	var disabled_style: StyleBoxFlat = _make_style(0.047, 0.019, 0.125, 0.5, Color(0.439, 0.251, 0.69, 0.5))
	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", hover_style)
	add_theme_stylebox_override("disabled", disabled_style)


func _make_style(r: float, g: float, b: float, a: float, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(r, g, b, a)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style


func _make_label_settings(font_size: int, font_color: Color) -> LabelSettings:
	var settings: LabelSettings = LabelSettings.new()
	settings.font = FONT_FILE
	settings.font_size = font_size
	settings.font_color = font_color
	return settings


func _on_pressed() -> void:
	if disabled:
		return
	card_pressed.emit(self)
