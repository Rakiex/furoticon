extends Control


## Emits when the Grid creates entries on (re-)initialization, for each one.
signal entry_created(entry: Control, data_index: int)
## Emits when a Grid entry changes what Item it represents, from scrolling or re-indexing or whatnot.
signal entry_refreshed(entry: Control, data_index: int)


var COLUMNS := 6
var ROWS := 7
var LIMIT := COLUMNS*ROWS

var entry_template: Control
var data_count := 0
var entry_to_dataindex := {}
@export var entry_size := Vector2(45.0,63.0)#: # 15,21   30,42   45,63   60,84
	#set(_a):
		#entry_size = _a
		#COLUMNS = $Clip/Grid.size.x / entry_size.x
		#ROWS = $Clip/Grid.size.y / entry_size.y
		#LIMIT = COLUMNS*ROWS

var scroll_drag_tracker :float = 0.0
var scroll_touch_tracker = 0

@onready var Scroll :VScrollBar = $Scroll
@onready var Grid :GridContainer = $Clip/Grid

## For some god-forsaken reason, Scroll events fire twice no matter what. Ugh.
var already_scroll:=false


func _process(delta: float) -> void:
	already_scroll = false

func fill_grid(node: Control, count: int) -> void:
	
	COLUMNS = Grid.size.x / entry_size.x
	ROWS = Grid.size.y / entry_size.y
	LIMIT = COLUMNS*ROWS
	
	Grid.columns = COLUMNS
	
	printt(CardData.BASE.size(), count, COLUMNS, ROWS, LIMIT, Grid.columns, Grid.size.y, Scroll.page)
	
	## Store the node for later re-use (if the Grid changes size, entries are removed/added)
	entry_template = node
	
	## Create enough entries to fill the grid.
	for i in LIMIT:
		var entry = entry_template.duplicate()
		entry.custom_minimum_size = entry_size
		Grid.add_child(entry)
		entry_created.emit(entry, i)
		entry.hide()
	
	set_card_bank(0, count)
	resize_scroll()

## Rename to "set_grid"
func set_card_bank(start: float, count: int) -> void:
	
	var gonna_resize := data_count != count
	data_count = count
	
	#printt(start, data_count, LIMIT, Scroll.value, Scroll.max_value)
	# 1446	1500	54	241.0
	# 1458	1500	54	243.0 # 42 , 12
	# 244.0
	
	# 0.5 scroll ~~ 3 ~~ row 0 should be halfway off top
	
	var offset = fmod(start, float(COLUMNS))
	Grid.position.y = offset / COLUMNS * -entry_size.y
	start = int(start - offset)
	
	#printt('GridPos', Grid.position.y, start)
	
	for i in LIMIT:
		if start+i < data_count:
			refresh(i, start+i)
		else:
			Grid.get_child(i).hide()
	
	if gonna_resize:
		resize_scroll()


func resize_scroll() -> void:
	Scroll.value = 0
	## +1 for the off-screen part, another +1 for...some reason.
	Scroll.max_value = ((ceil(data_count/float(COLUMNS))) - ROWS) +2
	if Scroll.max_value == 0:
		Scroll.hide()
	else:
		Scroll.show()
		## So long as max_value is +1 what we wanted to set it at, everything just fucking works for some reason.
		Scroll.page = 1.0


func refresh(grid_index: int, data_index: int) -> void:
	var entry = Grid.get_child(grid_index)
	entry.show()
	entry_to_dataindex[entry] = data_index
	#printt('Refresh', grid_index, data_index)
	entry_refreshed.emit(entry, data_index)


func reset_scroll() -> void:
	Scroll.value = 0.0
	Grid.position.y = 0.0


func _scroll_value_change(value:float):
	
	## "Start" will be the 'cards' index of the current top-left card in the grid
	#var start := int(value) * COLUMNS
	var start := value * COLUMNS
	
	#printt('Scroll', value, start)
	
	set_card_bank(start, data_count)


func _gui_input(event):
	
	if event is InputEventMouseButton:
		if already_scroll:
			return
		already_scroll = true
		if event.pressed:
			## Wheel Up
			if event.button_index == 4:
				Scroll.value -= 1.0
			## Wheel Down
			if event.button_index == 5:
				Scroll.value += 1.0
	
	elif event is InputEventScreenDrag:
		
		## Adjust the force of the drag, so that the size of the scrollbar is considered
		var force = event.screen_relative.y
		force = force * (Scroll.max_value / 243.0)
		scroll_drag_tracker += force
		
		if abs(scroll_drag_tracker) > 1.0:
			force = floorf(scroll_drag_tracker)
			scroll_drag_tracker -= force
			Scroll.value += int(force)


func dataindex(entry: Control) -> int:
	return entry_to_dataindex[entry]
