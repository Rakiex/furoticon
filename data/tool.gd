extends Node
class_name Tool

static func scrub(x:String) -> String:
	return x.to_lower().replace(" ", "").replace("_", "").replace("'", "").replace(",", "")

static func get_file_name(x:String) -> String:
	return x.get_file().split(".")[0]

static func size_unique(array: Array) -> int:
	var count := 0
	var _a := []
	for x in array:
		if not x in _a:
			_a.append(x)
			count += 1
	return count
