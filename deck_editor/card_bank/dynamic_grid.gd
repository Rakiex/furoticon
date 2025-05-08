extends Control


## Emits when the Grid creates entries on (re-)initialization, for each one.
signal entry_created(entry: Control, data_index: int)
## Emits when a Grid entry changes what Item it represents, from scrolling or re-indexing or whatnot.
signal entry_refreshed(entry: Control, data_index: int)


var COLUMNS := 6.0
var ROWS := 7.0
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


func _gui_input(event):
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				Scroll.value -= 1.0
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
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


func _scroll_value_change(value:float):
	
	## "Start" will be the 'cards' index of the current top-left card in the grid
	var start := value * COLUMNS
	
	set_card_bank(start, data_count)


func fill_grid(node: Control, count: int) -> void:
	
	COLUMNS = Grid.size.x / entry_size.x
	ROWS = Grid.size.y / entry_size.y
	LIMIT = COLUMNS*ROWS
	
	Grid.columns = COLUMNS
	
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
	
	var offset = fmod(start, float(COLUMNS))
	Grid.position.y = offset / COLUMNS * -entry_size.y
	start = int(start - offset)
	
	#printt('DynamicGrid.gd/CardBank', COLUMNS, ROWS, LIMIT, offset, start, data_count)
	
	for i in LIMIT:
		if start+i < data_count:
			refresh(i, start+i)
		else:
			Grid.get_child(i).hide()
	
	if gonna_resize:
		resize_scroll()


func resize(to:Vector2) -> void:
	size = to
	
	var old_limit = LIMIT
	COLUMNS = to.x / entry_size.x
	ROWS = (to.y / entry_size.y) + 1.0
	LIMIT = COLUMNS*ROWS
	
	## "Round" Limit to the nearest multiple of Column
	var div = LIMIT / COLUMNS
	if int(div) != div:
		LIMIT = ceil(div) * COLUMNS
	
	## Create or Remove entries to keep the grid full.
	if entry_template != null:
		if LIMIT < old_limit:
			var children = Grid.get_children()
			for i in range(old_limit - LIMIT):
				var ch = children[i + LIMIT]
				Grid.remove_child(ch)
				ch.queue_free()
		elif LIMIT > old_limit:
			for i in range(LIMIT - old_limit):
				var entry = entry_template.duplicate()
				entry.custom_minimum_size = entry_size
				Grid.add_child(entry)
				entry_created.emit(entry, i)
				entry.hide()
	
	Grid.columns = COLUMNS
	
	#printt('DynamicGrid.gd/Resize', to.y, COLUMNS, ROWS, LIMIT)
	
	resize_scroll()
	reset_scroll()


func resize_scroll() -> void:
	Scroll.value = 0
	## +1 for the off-screen part, another +1 for...some reason.
	Scroll.max_value = ((ceil(data_count/float(COLUMNS))) - ROWS) +2 # Columns is 10 when it really should be 9?
	if Scroll.max_value == 0:
		Scroll.hide()
	else:
		Scroll.show()
		## So long as max_value is +1 what we wanted to set it at, everything just fucking works for some reason.
		Scroll.page = 1.0


func reset_scroll() -> void:
	Scroll.value = 0.0
	Grid.position.y = 0.0


func refresh(grid_index: int, data_index: int) -> void:
	var entry = Grid.get_child(grid_index)
	entry.show()
	entry_to_dataindex[entry] = data_index
	entry_refreshed.emit(entry, data_index)


func dataindex(entry: Control) -> int:
	return entry_to_dataindex[entry]
