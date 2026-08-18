@tool
class_name YandexRemoteConfig
extends RefCounted

## Manages Remote Configuration flags and A/B testing parameters.

signal flags_loaded(flags: Dictionary)

var _core: Node = null
var _flags: Dictionary = {}

func _init(core: Node) -> void:
	_core = core

## Retrieves remote configuration flags.
## Parameters:
## - client_features: Array of { "name": String, "value": String }
## - default_flags: Dictionary of default fallback key-values
func get_flags(client_features: Array = [], default_flags: Dictionary = {}) -> Dictionary:
	var params: Dictionary = {
		"clientFeatures": client_features,
		"defaultFlags": default_flags
	}
	
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getFlags", [JSON.stringify(params)])
	else:
		res = _core.mock_bridge.get_flags(params)
	
	if res.get("success", false):
		_flags = res.get("data", {})
		flags_loaded.emit(_flags)
		return _flags
	return default_flags

## Returns a specific flag value as String with fallback.
func get_flag_string(key: String, default_value: String = "") -> String:
	return str(_flags.get(key, default_value))

## Returns a specific flag value as bool with fallback.
func get_flag_bool(key: String, default_value: bool = false) -> bool:
	var val: Variant = _flags.get(key)
	if val == null:
		return default_value
	if val is bool:
		return val
	return str(val).to_lower() in ["true", "1", "yes"]

## Returns a specific flag value as int with fallback.
func get_flag_int(key: String, default_value: int = 0) -> int:
	var val: Variant = _flags.get(key)
	if val == null:
		return default_value
	return int(val)
