extends Node



func _ready() -> void:
	
	if OS.has_feature("web"):
		var deck_editor = load("res://deck_editor/deck.tscn").instantiate()
		add_child(deck_editor)
		#queue_free()
	
	else:
		var title = load("res://scene/title.tscn").instantiate()
		add_child(title)
		#queue_free()
