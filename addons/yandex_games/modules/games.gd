@tool
class_name YandexGamesAPI
extends RefCounted

## Cross-promotion and games catalog API (features.GamesAPI).

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Retrieves all games published by the same developer along with developerURL.
## Returns: { "developerURL": String, "games": Array[Dictionary] }
func get_all_games() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getAllGames")
		if res.get("success", false):
			var data: Dictionary = res.get("data", {})
			var games_list: Array[Dictionary] = []
			for item in data.get("games", []):
				if item is Dictionary:
					games_list.append(item)
			return {
				"developerURL": str(data.get("developerURL", "")),
				"games": games_list
			}
		return { "developerURL": "", "games": [] }
	else:
		return _core.mock_bridge.get_all_games()

## Convenience shortcut to retrieve just the list of games published by the same developer.
func get_games_list() -> Array[Dictionary]:
	var all_data: Dictionary = await get_all_games()
	var list: Array[Dictionary] = []
	for g in all_data.get("games", []):
		if g is Dictionary:
			list.append(g)
	return list

## Retrieves details of a specific game by App ID.
func get_game_by_id(app_id: Variant) -> Dictionary:
	var res: Dictionary
	var app_id_str: String = str(app_id)
	if _core.is_web():
		res = await _core.call_js_async("getGameByID", [app_id_str])
	else:
		res = _core.mock_bridge.get_game_by_id(app_id_str)
	return res.get("data", {}) if res.get("success", false) else {}
