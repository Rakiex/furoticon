extends ColorRect


var goal := 0:
	set(v):
		goal = v
		$ProgressBar.max_value = goal

var value := 0:
	set(v):
		value = v
		$ProgressBar.value = value
		
		$ProgressBar/Progress.text = "Cards: %s/%s" % [value,goal]
