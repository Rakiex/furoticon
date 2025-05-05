extends Control


signal became_empty()
signal became_valid_filter()
signal changed()

const REGEX_ALPHABET_GLYPHS :Array = [
	"c", # (C)ard (N)ame // (?=:.) would prevent filter until there is an actual value
	"a", # (A)rtist Name
	"s", # (S)kill Text
	"f", # (F)lavor Text
	#"k", # (K)eyword Skills
	"t", # (T)ype
	"d", # (D)efining Types
	"g", # (G)ender
	#"gp", # (G)ender (P)oint Cost
	"e", # (E)dition
	"r" # (R)arity
	]

var exists := false

var pre = '+'
var tag = 'c'
var op = '='
var param = ''
var alpha = 0

# ^ Sort (Maybe doesn't make too much sense as a pre-code...)
# ~ Or
# +
# -
# -~ Exlusive-Or (Cards that only match one, but no more, of filters using it)
# # Count? (Or just have a number somewhere that lists all cards in bank, which will accomplish the same thing)

# >
# >=
# =
# <=
# <


func _change_pre_text(new_text: String) -> void:
	if new_text == '':
		pre = '+'
		check_empty()
	
	pre = Tool.scrub(new_text)
	changed.emit()
	
	if exists:
		return
	exists = true
	became_valid_filter.emit()


func _change_tag(new_text: String) -> void:
	if new_text == '':
		tag = 'c'
		check_empty()
	
	new_text = Tool.scrub(new_text)
	tag = new_text
	if new_text in REGEX_ALPHABET_GLYPHS:
		alpha = 0
		$Filter/Operator.hide()
	else:
		alpha = 1
		$Filter/Operator.show()
	changed.emit()
	
	if exists:
		return
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
	exists = true
	became_valid_filter.emit()


func check_empty() -> bool:
	if $Filter/Pre/LineEdit.text != '': return false
	if $Filter/Tag/LineEdit.text != '': return false
	if $Filter/Operator/LineEdit.text != '': return false
	if $Filter/Param/LineEdit.text != '': return false
	became_empty.emit()
	return true


func _on_button_pressed() -> void:
	pass # Replace with function body.


func set_all(_pre:String, _tag:String, _op:String, _param:String) -> void:
	#$Filter/Pre/LineEdit.text = _pre
	$Filter/Tag/LineEdit.text = _tag
	#$Filter/Operator/LineEdit.text = _op
	$Filter/Param/LineEdit.text = _param
	#pre = _pre
	tag = _tag
	#op = _op
	param = _param
	if tag in REGEX_ALPHABET_GLYPHS:
		alpha = 0
		$Filter/Operator.hide()
	else:
		alpha = 1
		$Filter/Operator.show()
	changed.emit()
	if exists:
		return
	exists = true
	became_valid_filter.emit()
