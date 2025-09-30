# TextUtils.gd
class_name TextUtils
extends Object

## Convert enum values (ints) to display strings.
static func enum_values_to_strings(enum_keys: Array, enum_dictionary: Dictionary, display_label_map: Dictionary = {}) -> Array[String]:
	var labels: Array[String] = []
	for enum_key in enum_keys:
		var enum_string = enum_dictionary[enum_key]
		if enum_string != null:
			labels.append(str(enum_string))
	return labels

## Join enum values into a single string using a separator.
static func enum_values_to_joined(enum_values: Array, enum_dictionary: Dictionary, separator: String = " - ", display_label_map: Dictionary = {}) -> String:
	var labels: Array[String] = enum_values_to_strings(enum_values, enum_dictionary, display_label_map)
	return separator.join(labels)


	# or: return separator.join(PackedStringArray(labels))

## Convert a bitmask of flags into an array of display strings.
static func bitmask_to_strings(mask: int, label_map: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for flag_value in label_map.keys():
		var value_int: int = int(flag_value)
		if (mask & value_int) != 0:
			labels.append(str(label_map[flag_value]))
	return labels
