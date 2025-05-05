extends Control


const PRECON_PLATE = preload("res://deck_editor/precon_plate.tscn")


signal plate_selected(int)


var _progress_idx := 0


func _process(_delta:float) -> void:
	# Load every precon
	if _progress_idx < DeckData.ORDER.size():
		load_precon_plate(_progress_idx)
		_progress_idx += 1
	else:
		set_process(false)


func load_precon_plate(idx:int) -> void:
	var precon_plate = PRECON_PLATE.instantiate()
	var did := DeckData.ORDER[idx]
	precon_plate.get_node("Label").text = DeckData.NAME[did]
	precon_plate.get_node("Owner").texture = load(CardLib.get_path_to_art(DeckData.OWNER[did]))
	var cids :Array = DeckData.CARDS[did]
	precon_plate.get_node("Furre1").texture = load(CardLib.get_path_to_art(cids[0]))
	precon_plate.get_node("Furre2").texture = load(CardLib.get_path_to_art(cids[1]))
	precon_plate.get_node("Other1").texture = load(CardLib.get_path_to_art(cids[2]))
	precon_plate.get_node("Other2").texture = load(CardLib.get_path_to_art(cids[3]))
	precon_plate.get_node("Button").pressed.connect(_plate_selected.bind(did))
	$ScrollContainer/GridContainer.add_child(precon_plate)
	printt(idx, did, DeckData.NAME[did])


func _plate_selected(idx:int) -> void:
	plate_selected.emit(idx)
	queue_free()


func _on_button_pressed():
	get_parent().remove_child(self)
	queue_free()
