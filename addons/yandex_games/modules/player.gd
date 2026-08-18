@tool
class_name YandexPlayer
extends RefCounted

## Manages Player Profile, Authentication, Cloud Saves, and Stats.

signal authorized(player_info: Dictionary)
signal auth_failed(error: String)
signal data_loaded(data: Dictionary)
signal data_saved
signal stats_loaded(stats: Dictionary)
signal stats_saved

var _core = null
var _info: Dictionary = {
	"isAuthorized": false,
	"uniqueId": "",
	"name": "",
	"photoSmall": "",
	"photoMedium": "",
	"photoLarge": "",
	"payingStatus": ""
}

func _init(core) -> void:
	_core = core

## Initializes the Player object with optional parameters (e.g. scopes, signed).
func init(options: Dictionary = {}) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("initPlayer", [JSON.stringify(options)])
	else:
		res = _core.mock_bridge.init_player(options)
	
	if res.get("success", false):
		_info = res.get("data", {})
		if is_authorized():
			authorized.emit(_info)
	else:
		auth_failed.emit(res.get("error", "Player init failed"))
	return _info

## Opens the native Yandex Games authorization popup dialog.
func open_auth_dialog() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("openAuthDialog")
	else:
		res = await _core.mock_bridge.open_auth_dialog()
	
	if res.get("success", false):
		_info = res.get("data", {})
		if is_authorized():
			authorized.emit(_info)
	else:
		auth_failed.emit(res.get("error", "Auth dialog failed"))
	return _info

## Returns true if the current player is authorized via Yandex ID.
func is_authorized() -> bool:
	return _info.get("isAuthorized", false)

## Returns the unique permanent identifier of the player.
func get_id() -> String:
	return _info.get("uniqueId", "")

## Returns the public nickname/name of the player.
func get_name() -> String:
	return _info.get("name", "")

## Returns the player's avatar photo URL ("small", "medium", or "large").
func get_photo(size: String = "medium") -> String:
	match size.to_lower():
		"small":
			return _info.get("photoSmall", "")
		"large":
			return _info.get("photoLarge", "")
		_:
			return _info.get("photoMedium", "")

## Returns player paying status ("paying" or "").
func get_paying_status() -> String:
	return _info.get("payingStatus", "")

## Returns cryptographic signature for backend validation if initialized with signed: true.
func get_signature() -> String:
	return _info.get("signature", "")

## Returns user IDs across other games by the same developer.
func get_ids_per_game() -> Array:
	if _core.is_web():
		var res = await _core.call_js_async("getPlayerIDsPerGame")
		return res.get("data", []) if res.get("success", false) else []
	else:
		var res = _core.mock_bridge.get_player_ids_per_game()
		return res.get("data", [])

## Retrieves in-game data (cloud save). Pass an Array of String keys or null to retrieve all.
func get_data(keys: Variant = null) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		var keys_json = JSON.stringify(keys) if keys != null else ""
		res = await _core.call_js_async("getPlayerData", [keys_json])
	else:
		res = _core.mock_bridge.get_player_data(keys)
	
	var data = res.get("data", {}) if res.get("success", false) else {}
	data_loaded.emit(data)
	return data

## Saves in-game data to the cloud. Set flush to true for immediate synchronization.
func set_data(data: Dictionary, flush: bool = false) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("setPlayerData", [JSON.stringify(data), flush])
	else:
		res = _core.mock_bridge.set_player_data(data, flush)
	
	var ok = res.get("success", false)
	if ok:
		data_saved.emit()
	return ok

## Retrieves numeric player statistics. Pass an Array of String keys or null for all stats.
func get_stats(keys: Variant = null) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		var keys_json = JSON.stringify(keys) if keys != null else ""
		res = await _core.call_js_async("getPlayerStats", [keys_json])
	else:
		res = _core.mock_bridge.get_player_stats(keys)
	
	var stats = res.get("data", {}) if res.get("success", false) else {}
	stats_loaded.emit(stats)
	return stats

## Sets numeric player statistics in cloud.
func set_stats(stats: Dictionary) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("setPlayerStats", [JSON.stringify(stats)])
	else:
		res = _core.mock_bridge.set_player_stats(stats)
	
	var ok = res.get("success", false)
	if ok:
		stats_saved.emit()
	return ok

## Atomically increments numeric stats in cloud.
## Example: increment_stats({ "coins": 50, "levels_completed": 1 })
func increment_stats(increments: Dictionary) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("incrementPlayerStats", [JSON.stringify(increments)])
	else:
		res = _core.mock_bridge.increment_player_stats(increments)
	
	var updated_stats = res.get("data", {}) if res.get("success", false) else {}
	if res.get("success", false):
		stats_saved.emit()
	return updated_stats
