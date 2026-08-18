@tool
class_name YandexLeaderboards
extends RefCounted

## Manages Leaderboards, player scores, rankings, and entries.

signal score_set(leaderboard_name: String, score: int)
signal score_failed(leaderboard_name: String, error: String)
signal entries_loaded(leaderboard_name: String, entries: Array)

var _core = null

func _init(core) -> void:
	_core = core

## Retrieves description and metadata of a specific leaderboard.
func get_description(leaderboard_name: String) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getLeaderboardDescription", [leaderboard_name])
	else:
		res = _core.mock_bridge.get_leaderboard_description(leaderboard_name)
	return res.get("data", {}) if res.get("success", false) else {}

## Sets the score for the current player in the given leaderboard.
func set_score(leaderboard_name: String, score: int, extra_data: String = "") -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("setLeaderboardScore", [leaderboard_name, score, extra_data])
	else:
		res = _core.mock_bridge.set_leaderboard_score(leaderboard_name, score, extra_data)
	
	var ok = res.get("success", false)
	if ok:
		score_set.emit(leaderboard_name, score)
	else:
		score_failed.emit(leaderboard_name, res.get("error", "Failed to set score"))
	return ok

## Retrieves the current player's entry and rank in the given leaderboard.
func get_player_entry(leaderboard_name: String) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getLeaderboardPlayerEntry", [leaderboard_name])
	else:
		res = _core.mock_bridge.get_leaderboard_player_entry(leaderboard_name)
	return res.get("data", {}) if res.get("success", false) else {}

## Retrieves leaderboard entries with custom options.
## Options: { "quantityTop": int, "includeUser": bool, "quantityAround": int, "avatarSizeSmall": String, "avatarSizeMedium": String, "avatarSizeLarge": String }
func get_entries(leaderboard_name: String, options: Dictionary = {}) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getLeaderboardEntries", [leaderboard_name, JSON.stringify(options)])
	else:
		res = _core.mock_bridge.get_leaderboard_entries(leaderboard_name, options)
	
	var data = res.get("data", {}) if res.get("success", false) else {}
	var entries = data.get("entries", [])
	entries_loaded.emit(leaderboard_name, entries)
	return data
