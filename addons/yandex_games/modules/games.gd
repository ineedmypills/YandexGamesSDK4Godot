@tool
class_name YandexGamesAPI
extends RefCounted

## Cross-promotion and games catalog API (features.GamesAPI).

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Retrieves a list of other games published by the same developer.
func get_all_games() -> Array[Dictionary]:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getAllGames")
		var games_list: Array[Dictionary] = []
		if res.get("success", false):
			for item: Dictionary in res.get("data", []):
				games_list.append(item)
		return games_list
	else:
		return _core.mock_bridge.get_all_games()

## Retrieves details of a specific game by App ID.
func get_game_by_id(app_id: String) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getGameByID", [app_id])
	else:
		res = _core.mock_bridge.get_game_by_id(app_id)
	return res.get("data", {}) if res.get("success", false) else {}
