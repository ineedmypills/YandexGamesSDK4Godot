@tool
class_name YandexMockBridge
extends RefCounted

## Offline / Editor Mock Bridge for Yandex Games SDK in Godot 4.x
## Simulates all platform features, network delays, and local disk persistence.

const MOCK_SAVE_PATH = "user://yandex_mock_data.json"

var is_initialized: bool = false
var is_player_authorized: bool = true
var player_unique_id: String = "mock_player_12345"
var player_name: String = "Test Player (Editor)"
var player_photo_url: String = "https://avatars.mds.yandex.net/get-yapic/0/0-0/islands-200"

var _mock_data: Dictionary = {}
var _mock_stats: Dictionary = {}
var _mock_leaderboards: Dictionary = {}
var _mock_purchases: Array = []
var _mock_catalog: Array = [
	{
		"id": "coins_100",
		"title": "100 Coins",
		"description": "Bag of 100 gold coins",
		"imageURI": "",
		"price": "50 YAN",
		"priceValue": "50",
		"priceCurrencyCode": "YAN"
	},
	{
		"id": "no_ads",
		"title": "Disable Ads",
		"description": "Permanent ad removal",
		"imageURI": "",
		"price": "100 YAN",
		"priceValue": "100",
		"priceCurrencyCode": "YAN"
	}
]
var _banner_showing: bool = false
var _reviewed: bool = false
var _shortcut_installed: bool = false

func _init() -> void:
	_load_mock_file()

func _log(msg: String) -> void:
	print_rich("[color=cyan][YandexGames Mock][/color] %s" % msg)

func _load_mock_file() -> void:
	if FileAccess.file_exists(MOCK_SAVE_PATH):
		var file = FileAccess.open(MOCK_SAVE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_str) == OK and json.data is Dictionary:
				_mock_data = json.data.get("data", {})
				_mock_stats = json.data.get("stats", {})
				_mock_leaderboards = json.data.get("leaderboards", {})
				_mock_purchases = json.data.get("purchases", [])
				_reviewed = json.data.get("reviewed", false)
				_shortcut_installed = json.data.get("shortcut_installed", false)

func _save_mock_file() -> void:
	var file = FileAccess.open(MOCK_SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_dict = {
			"data": _mock_data,
			"stats": _mock_stats,
			"leaderboards": _mock_leaderboards,
			"purchases": _mock_purchases,
			"reviewed": _reviewed,
			"shortcut_installed": _shortcut_installed
		}
		file.store_string(JSON.stringify(save_dict, "\t"))

# --- Core Lifecycle ---

func init(options: Dictionary) -> Dictionary:
	_log("SDK Initialized in Mock Mode (options: %s)" % str(options))
	is_initialized = true
	return {
		"success": true,
		"data": {
			"environment": get_environment(),
			"device": get_device_info()
		}
	}

func loading_ready() -> void:
	_log("LoadingAPI.ready() triggered.")

func gameplay_start() -> void:
	_log("GameplayAPI.start() triggered.")

func gameplay_stop() -> void:
	_log("GameplayAPI.stop() triggered.")

func server_time() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

func is_available_method(method_name: String) -> bool:
	_log("isAvailableMethod('%s') -> true" % method_name)
	return true

# --- Environment & Device ---

func get_environment() -> Dictionary:
	return {
		"app": { "id": "mock_app_id" },
		"browser": { "lang": "ru" },
		"i18n": { "lang": "ru", "tld": "ru" },
		"payload": "",
		"fullscreen": false
	}

func get_device_info() -> Dictionary:
	var os_name = OS.get_name().to_lower()
	var is_mob = (os_name == "android" or os_name == "ios")
	return {
		"type": "mobile" if is_mob else "desktop",
		"isMobile": is_mob,
		"isTablet": false,
		"isDesktop": not is_mob,
		"isTV": false
	}

# --- Fullscreen ---

func fullscreen_status() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func fullscreen_request() -> Dictionary:
	_log("Fullscreen requested.")
	return { "success": true, "status": "on" }

func fullscreen_exit() -> Dictionary:
	_log("Fullscreen exit.")
	return { "success": true, "status": "off" }

# --- Ads ---

func show_fullscreen_adv(callback: Callable) -> void:
	_log("Interstitial Ad: Opening...")
	callback.call({ "event": "open" })
	
	# Simulate 0.5s ad playback in editor
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(0.5).timeout
	
	_log("Interstitial Ad: Closed.")
	callback.call({ "event": "close", "wasShown": true })

func show_rewarded_video(callback: Callable) -> void:
	_log("Rewarded Video Ad: Opening...")
	callback.call({ "event": "open" })
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(0.8).timeout
	
	_log("Rewarded Video Ad: Reward Granted!")
	callback.call({ "event": "rewarded" })
	
	_log("Rewarded Video Ad: Closed.")
	callback.call({ "event": "close", "wasShown": true })

func get_banner_adv_status() -> Dictionary:
	return { "success": true, "stickyAdvIsShowing": _banner_showing, "reason": null }

func show_banner_adv() -> Dictionary:
	_log("Sticky Banner shown.")
	_banner_showing = true
	return { "success": true, "stickyAdvIsShowing": true, "reason": null }

func hide_banner_adv() -> Dictionary:
	_log("Sticky Banner hidden.")
	_banner_showing = false
	return { "success": true, "stickyAdvIsShowing": false }

# --- Player & Auth ---

func init_player(_options: Dictionary = {}) -> Dictionary:
	_log("Player initialized (Authorized: %s, Name: %s)" % [str(is_player_authorized), player_name])
	return {
		"success": true,
		"data": {
			"isAuthorized": is_player_authorized,
			"uniqueId": player_unique_id if is_player_authorized else "",
			"name": player_name if is_player_authorized else "",
			"photoSmall": player_photo_url if is_player_authorized else "",
			"photoMedium": player_photo_url if is_player_authorized else "",
			"photoLarge": player_photo_url if is_player_authorized else "",
			"payingStatus": "paying" if is_player_authorized else ""
		}
	}

func open_auth_dialog() -> Dictionary:
	_log("Simulating player authorization dialog...")
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(0.3).timeout
	is_player_authorized = true
	_log("Player authorized successfully.")
	return init_player()

func get_player_data(keys: Variant = null) -> Dictionary:
	_log("getPlayerData() -> %s" % str(_mock_data))
	if keys == null:
		return { "success": true, "data": _mock_data.duplicate(true) }
	
	var result = {}
	if keys is Array:
		for k in keys:
			if _mock_data.has(k):
				result[k] = _mock_data[k]
	elif keys is String:
		if _mock_data.has(keys):
			result[keys] = _mock_data[keys]
	return { "success": true, "data": result }

func set_player_data(data: Dictionary, _flush: bool = false) -> Dictionary:
	for k in data.keys():
		_mock_data[k] = data[k]
	_save_mock_file()
	_log("setPlayerData() -> saved %d keys to %s" % [data.size(), MOCK_SAVE_PATH])
	return { "success": true }

func get_player_stats(keys: Variant = null) -> Dictionary:
	if keys == null:
		return { "success": true, "data": _mock_stats.duplicate(true) }
	var result = {}
	if keys is Array:
		for k in keys:
			if _mock_stats.has(k):
				result[k] = _mock_stats[k]
	return { "success": true, "data": result }

func set_player_stats(stats: Dictionary) -> Dictionary:
	for k in stats.keys():
		_mock_stats[k] = stats[k]
	_save_mock_file()
	_log("setPlayerStats() -> %s" % str(stats))
	return { "success": true }

func increment_player_stats(increments: Dictionary) -> Dictionary:
	for k in increments.keys():
		var val = _mock_stats.get(k, 0)
		_mock_stats[k] = val + increments[k]
	_save_mock_file()
	_log("incrementPlayerStats() -> %s" % str(_mock_stats))
	return { "success": true, "data": _mock_stats.duplicate(true) }

func get_player_ids_per_game() -> Dictionary:
	return {
		"success": true,
		"data": [
			{ "appID": "mock_app_1", "userID": "mock_user_1" },
			{ "appID": "mock_app_2", "userID": "mock_user_2" }
		]
	}

# --- Leaderboards ---

func get_leaderboard_description(name: String) -> Dictionary:
	return {
		"success": true,
		"data": {
			"name": name,
			"title": name.capitalize(),
			"type": "numeric",
			"description": { "invert_sort_order": false, "decimal_offset": 0 }
		}
	}

func set_leaderboard_score(name: String, score: int, extra_data: String = "") -> Dictionary:
	if not _mock_leaderboards.has(name):
		_mock_leaderboards[name] = []
	
	var list: Array = _mock_leaderboards[name]
	var found = false
	for entry in list:
		if entry.get("player", {}).get("uniqueID") == player_unique_id:
			entry["score"] = score
			entry["extraData"] = extra_data
			found = true
			break
	
	if not found:
		list.append({
			"score": score,
			"extraData": extra_data,
			"rank": 1,
			"player": {
				"uniqueID": player_unique_id,
				"publicName": player_name,
				"avatarUrlSmall": player_photo_url
			}
		})
	
	# Sort descending by score
	list.sort_custom(func(a, b): return a.score > b.score)
	for i in range(list.size()):
		list[i]["rank"] = i + 1
	
	_save_mock_file()
	_log("setLeaderboardScore('%s', %d)" % [name, score])
	return { "success": true }

func get_leaderboard_player_entry(name: String) -> Dictionary:
	var list: Array = _mock_leaderboards.get(name, [])
	for entry in list:
		if entry.get("player", {}).get("uniqueID") == player_unique_id:
			return { "success": true, "data": entry }
	return {
		"success": true,
		"data": {
			"score": 0,
			"rank": 0,
			"extraData": "",
			"player": { "uniqueID": player_unique_id, "publicName": player_name }
		}
	}

func get_leaderboard_entries(name: String, options: Dictionary = {}) -> Dictionary:
	var list: Array = _mock_leaderboards.get(name, [])
	if list.is_empty():
		# Generate sample entries for editor testing
		for i in range(1, 6):
			list.append({
				"score": 1000 - i * 150,
				"rank": i,
				"extraData": "",
				"player": {
					"uniqueID": "mock_bot_%d" % i,
					"publicName": "Player Bot %d" % i,
					"avatarUrlSmall": player_photo_url
				}
			})
		_mock_leaderboards[name] = list
	
	return {
		"success": true,
		"data": {
			"leaderboard": { "name": name, "title": name.capitalize() },
			"entries": list,
			"userRank": 1
		}
	}

# --- Payments ---

func get_catalog() -> Dictionary:
	return { "success": true, "data": _mock_catalog }

func get_purchases() -> Dictionary:
	return { "success": true, "data": _mock_purchases }

func purchase(options: Dictionary) -> Dictionary:
	var product_id = options.get("id", "")
	var token = "mock_token_" + str(Time.get_ticks_msec())
	var purchase_entry = {
		"productID": product_id,
		"purchaseToken": token,
		"developerPayload": options.get("developerPayload", "")
	}
	_mock_purchases.append(purchase_entry)
	_save_mock_file()
	_log("Purchase completed for '%s' (token: %s)" % [product_id, token])
	return { "success": true, "data": purchase_entry }

func consume_purchase(token: String) -> Dictionary:
	var index_to_remove = -1
	for i in range(_mock_purchases.size()):
		if _mock_purchases[i].get("purchaseToken") == token:
			index_to_remove = i
			break
	if index_to_remove >= 0:
		_mock_purchases.remove_at(index_to_remove)
		_save_mock_file()
		_log("Consumed purchase token '%s'" % token)
		return { "success": true }
	return { "success": false, "error": "Token not found" }

# --- Feedback / Review ---

func can_review() -> Dictionary:
	return {
		"success": true,
		"data": {
			"value": not _reviewed,
			"reason": "GAME_RATED" if _reviewed else null
		}
	}

func request_review() -> Dictionary:
	_log("Simulating game review popup...")
	_reviewed = true
	_save_mock_file()
	return { "success": true, "data": { "value": true, "feedbackSent": true } }

# --- Shortcut ---

func can_show_prompt() -> Dictionary:
	return {
		"success": true,
		"data": {
			"canShow": not _shortcut_installed
		}
	}

func show_prompt() -> Dictionary:
	_log("Simulating shortcut installation prompt...")
	_shortcut_installed = true
	_save_mock_file()
	return { "success": true, "data": { "outcome": "accepted" } }

# --- Remote Config / Flags ---

func get_flags(params: Dictionary = {}) -> Dictionary:
	var defaults = params.get("defaultFlags", {})
	_log("getFlags() -> returning defaults: %s" % str(defaults))
	return { "success": true, "data": defaults }

# --- Cross-Promotion / Games ---

func get_all_games() -> Dictionary:
	return {
		"success": true,
		"data": [
			{ "appID": "mock_game_1", "title": "Example Game 1", "url": "https://yandex.ru/games" },
			{ "appID": "mock_game_2", "title": "Example Game 2", "url": "https://yandex.ru/games" }
		]
	}

func get_game_by_id(app_id: String) -> Dictionary:
	return {
		"success": true,
		"data": { "appID": app_id, "title": "Example Game", "url": "https://yandex.ru/games" }
	}

# --- Clipboard ---

func clipboard_write_text(text: String) -> Dictionary:
	DisplayServer.clipboard_set(text)
	_log("Clipboard set to: %s" % text)
	return { "success": true }

# --- Multiplayer Sessions ---

func multiplayer_init_sessions(options: Dictionary) -> Dictionary:
	var count = options.get("count", 1)
	_log("Multiplayer sessions initialized (count: %d)" % count)
	var sample_opponents = []
	for i in range(count):
		sample_opponents.append({
			"id": "mock_session_%d" % (i + 1),
			"meta": { "meta1": 100 * (i + 1), "meta2": i + 1, "meta3": 0 },
			"player": { "name": "Opponent Bot %d" % (i + 1), "avatar": player_photo_url },
			"timeline": [
				{ "id": "1", "time": 100, "payload": { "action": "start" } },
				{ "id": "2", "time": 500, "payload": { "action": "move", "x": 10, "y": 20 } }
			]
		})
	return { "success": true, "data": sample_opponents }

func multiplayer_commit(payload: Dictionary) -> void:
	_log("Multiplayer transaction committed: %s" % str(payload))

func multiplayer_push(meta: Dictionary) -> Dictionary:
	_log("Multiplayer session pushed to server (meta: %s)" % str(meta))
	return { "success": true }
