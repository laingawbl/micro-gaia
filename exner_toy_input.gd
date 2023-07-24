extends Control

@onready var tree: Tree = $Content/Input/Ics/ICEdit
@onready var scroll: HScrollBar = $Content/Input/Ics/TopBar/ICScroll

const nDispCols = 10

var row_ofs: int = 0:
	set = _set_row_ofs,
	get = _get_row_ofs

var needs_layout: bool = false

var editing_params: bool = false:
	set = _set_editing_params,
	get = _get_editing_params

var collapse: bool = false:
	set = _set_collapse,
	get = _get_collapse


func _set_row_ofs(p) -> void:
	row_ofs = clamp(p, 0, SimData.nX - nDispCols)
	needs_layout = true


func _get_row_ofs() -> int:
	return row_ofs


func _set_collapse(p) -> void:
	collapse = p
	$Content/Ribbon/TLButtons/Expand.set_pressed_no_signal(p)
	redo_viz()


func _get_collapse() -> bool:
	return collapse


func _set_editing_params(p) -> void:
	editing_params = p
	$Content/Ribbon/TLButtons/Params.set_pressed_no_signal(p)
	redo_viz()


func _get_editing_params() -> bool:
	return editing_params


func redo_viz():
	if collapse:
		$Content/Input.visible = false
		$Content/Ribbon/TLButtons/Expand.self_modulate = Color(Color.WHITE, 0.5)
	else:
		$Content/Input.visible = true
		$Content/Ribbon/TLButtons/Expand.self_modulate = Color.WHITE

	if editing_params:
		$Content/Ribbon/TLButtons/Params.self_modulate = Color.WHITE
	else:
		$Content/Ribbon/TLButtons/Params.self_modulate = Color(Color.WHITE, 0.5)

	$Content/Input/Ics.visible = not editing_params
	$Content/Input/Params.visible = editing_params


func layout():
	scroll.set_value_no_signal(row_ofs)

	for j in range(1, nDispCols):
		tree.set_column_title(j, str(row_ofs + j - 1))

	var root = tree.get_root()
	var rows = root.get_children()
	for i in range(SimData.nR):
		var row = rows[i]
		row.set_text(0, str(SimData.nR - i))
		for j in range(1, nDispCols):
			(
				row
				. set_text(
					j, String.num(SimData.ICTemperature[row_ofs + j - 1][i], 1).pad_decimals(1)
				)
			)


func _ready():
	var input_helptext = FileAccess.open("res://input_helptext.bb.txt", FileAccess.READ).get_as_text(true)
	$Help/Panel/InnerMargins/Label.text = input_helptext
	
	var root = tree.create_item()
	tree.hide_root = true
	tree.set_columns(nDispCols)
	tree.set_column_title(0, "Level")

	scroll.min_value = 0
	scroll.max_value = SimData.nX
	scroll.page = nDispCols

	for i in range(SimData.nR):
		var row = root.create_child()
		row.set_custom_color(0, Color.WHITE)
		row.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
		row.set_suffix(0, "mb  ")
		row.set_text_alignment(0, HORIZONTAL_ALIGNMENT_RIGHT)
		for j in range(1, nDispCols):
			row.set_editable(j, true)
			row.set_custom_color(j, Color.DARK_SLATE_GRAY)
			row.set_custom_bg_color(j, Color.WHITE)

	needs_layout = true
	redo_viz()


func _process(_delta) -> void:
	if needs_layout:
		layout()
		needs_layout = false


func _on_prev_col_pressed():
	_set_row_ofs(row_ofs - 1)


func _on_next_col_pressed():
	_set_row_ofs(row_ofs + 1)


func _on_ic_scroll_value_changed(value):
	_set_row_ofs(value)


func _on_ic_edit_item_edited():
	var root = tree.get_root()
	var rows = root.get_children()
	for i in range(SimData.nR):
		var row = rows[i]
		for j in range(1, nDispCols):
			SimData.ICTemperature[row_ofs + j - 1][i] = row.get_text(j).to_float()
	needs_layout = true


func _on_expand_toggled(button_pressed):
	_set_collapse(button_pressed)


func _on_params_toggled(button_pressed):
	_set_editing_params(button_pressed)


func _on_help_toggled(button_pressed):
	$Help.visible = button_pressed
