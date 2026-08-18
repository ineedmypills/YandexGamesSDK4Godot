@tool
class_name YandexStorage
extends RefCounted

## Safe Local Storage handler that overcomes Safari/iOS private browsing restrictions.

var _core = null

func _init(core) -> void:
	_core = core

## Retrieves a stored string item by key.
func get_item(key: String, default_value: String = "") -> String:
	if _core.is_web():
		var res = await _core.call_js_async("getStorageItem", [key])
		if res.get("success", false) and res.get("value") != null:
			return str(res.get("value"))
		return default_value
	else:
		# Fallback to local ProjectSettings / ConfigFile / in-memory
		var config = ConfigFile.new()
		if config.load("user://yandex_safe_storage.cfg") == OK:
			return str(config.get_value("storage", key, default_value))
		return default_value

## Stores a string item by key.
func set_item(key: String, value: String) -> bool:
	if _core.is_web():
		var res = await _core.call_js_async("setStorageItem", [key, value])
		return res.get("success", false)
	else:
		var config = ConfigFile.new()
		config.load("user://yandex_safe_storage.cfg")
		config.set_value("storage", key, value)
		return config.save("user://yandex_safe_storage.cfg") == OK
