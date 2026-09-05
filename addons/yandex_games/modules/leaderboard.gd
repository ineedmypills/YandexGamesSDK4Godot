@tool
class_name YandexLeaderboards
extends RefCounted

## Manages Leaderboards, player scores, rankings, and entries.

signal score_set(leaderboard_name: String, score: int)
signal score_failed(leaderboard_name: String, error: String)
signal entries_loaded(leaderboard_name: String, entries: Array[Dictionary])

var _core: Node = null

func _init(core: Node) -> void:
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
	
	var ok: bool = res.get("success", false)
	if ok:
		score_set.emit(leaderboard_name, score)
	else:
		score_failed.emit(leaderboard_name, str(res.get("error", "Failed to set score")))
	return ok

var _pending_scores: Dictionary = {}
var _debounce_seq: int = 0

## Sets player score with a debounce delay (default 1.0s) to comply with Yandex 1 req/sec rate limit.
## If called multiple times within delay_sec, only the highest score is submitted once the timer expires.
func set_score_debounced(leaderboard_name: String, score: int, extra_data: String = "", delay_sec: float = 1.0) -> void:
	_debounce_seq += 1
	var current_seq: int = _debounce_seq
	
	if _pending_scores.has(leaderboard_name):
		var prev: Dictionary = _pending_scores[leaderboard_name]
		if score > int(prev.get("score", 0)):
			prev["score"] = score
			prev["extra_data"] = extra_data
		prev["seq"] = current_seq
	else:
		_pending_scores[leaderboard_name] = {
			"score": score,
			"extra_data": extra_data,
			"seq": current_seq
		}
	
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(delay_sec).timeout
	
	if _pending_scores.has(leaderboard_name):
		var data: Dictionary = _pending_scores[leaderboard_name]
		if int(data.get("seq", -1)) == current_seq:
			_pending_scores.erase(leaderboard_name)
			set_score(leaderboard_name, int(data.get("score", 0)), str(data.get("extra_data", "")))


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
	
	var data: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	var raw_entries: Array = data.get("entries", [])
	var entries: Array[Dictionary] = []
	for entry: Dictionary in raw_entries:
		entries.append(entry)
	entries_loaded.emit(leaderboard_name, entries)
	return data

## Loads an avatar texture for a leaderboard entry using the player's shared cache and offline generator.
func load_avatar_texture(avatar_url: String, fallback_name: String = "Player") -> Texture2D:
	if _core and _core.player:
		return await _core.player.load_texture_from_url(avatar_url, fallback_name)
	return null
