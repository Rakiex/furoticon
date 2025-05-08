extends Control


signal became_empty()
signal became_valid_filter()
signal changed()
signal removed()

const pre_list = ['^', '~', '+', '-', 'v']
const op_list = ['>', '>=', '=', '<=', '<']

var exists := false

var pre := '+'
var tag := 'c'
var op := '='
var param := ''
var type := 0

var bank

@onready var pre_edit := $Filter/Pre/LineEdit
@onready var tag_edit := $Filter/Tag/LineEdit
@onready var op_edit := $Filter/Operator/LineEdit
@onready var param_edit := $Filter/Param/LineEdit


func _change_pre_text(new_text: String) -> void:
	if new_text == '':
		pre = '+'
		check_empty()
	
	pre = Tool.scrub(new_text)
	changed.emit()
	
	if exists:
		return
	toggle_removability()
	exists = true
	became_valid_filter.emit()


func _change_tag(new_text: String) -> void:
	if new_text == '':
		tag = 'c'
		check_empty()
	
	new_text = Tool.scrub(new_text)
	tag = new_text
	#if new_text in REGEX_ALPHABET_GLYPHS:
		#alpha = 0
		#$Filter/Operator.hide()
	#else:
		#alpha = 1
		#$Filter/Operator.show()
	changed.emit()
	
	if exists:
		return
	toggle_removability()
	exists = true
	became_valid_filter.emit()


func _change_operator(new_text: String) -> void:
	if new_text == '':
		op = '='
		check_empty()
	
	op = Tool.scrub(new_text)
	changed.emit()
	
	if exists:
		return
	toggle_removability()
	exists = true
	became_valid_filter.emit()


func _change_parameter(new_text: String) -> void:
	if new_text == '':
		param = ''
		check_empty()
	
	param = Tool.scrub(new_text)
	changed.emit()
	
	if exists:
		return
	toggle_removability()
	exists = true
	became_valid_filter.emit()


func _press_remove() -> void:
	removed.emit()
	hide()
	queue_free()


func toggle_removability(on:=true) -> void:
	$Button.visible = on


func set_type(t:int) -> void:
	type = t
	if type == 2:
		$Filter/Operator.show()
	else:
		$Filter/Operator.hide()


func check_empty() -> bool:
	if $Filter/Pre/LineEdit.text != '': return false
	if $Filter/Tag/LineEdit.text != '': return false
	if $Filter/Operator/LineEdit.text != '': return false
	if $Filter/Param/LineEdit.text != '': return false
	became_empty.emit()
	return true


func set_all(_pre:String, _tag:String, _op:String, _param:String) -> void:
	pre_edit.text = _pre
	tag_edit.text = _tag
	op_edit.text = _op
	param_edit.text = _param
	pre = _pre
	tag = _tag
	op = _op
	param = _param
	changed.emit()
	if exists:
		return
	toggle_removability()
	exists = true
	became_valid_filter.emit()


func _on_pre_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed: return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var idx := pre_list.find(pre)
			idx = wrapi(idx-1, 0, pre_list.size())
			pre_edit.text = pre_list[idx]
			_change_pre_text(pre_list[idx])
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var idx := pre_list.find(pre)
			idx = wrapi(idx+1, 0, pre_list.size())
			pre_edit.text = pre_list[idx]
			_change_pre_text(pre_list[idx])
			return


func _on_tag_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed: return
		if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
			return
		
		var filters = bank.FILTERS
		var filkeys = filters.keys()
		var idx = filkeys.find(tag)
		var dir := 1
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			dir = -1
		
		idx = wrapi(idx+dir, 0, filkeys.size())
		tag_edit.text = filkeys[idx]
		_change_tag(filkeys[idx])


func _on_operator_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed: return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var idx := op_list.find(op)
			idx = wrapi(idx-1, 0, op_list.size())
			op_edit.text = op_list[idx]
			_change_operator(op_list[idx])
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var idx := op_list.find(op)
			idx = wrapi(idx+1, 0, op_list.size())
			op_edit.text = op_list[idx]
			_change_operator(op_list[idx])
			return


func _on_param_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed: return
		if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
			return
		
		var dir := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
		
		if param.is_valid_int():
			var x = int(param) + dir
			param_edit.text = str(x)
			_change_parameter(str(x))
