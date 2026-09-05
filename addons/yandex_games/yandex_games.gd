@tool
class_name YandexGamesNode
extends Node

## Yandex Games SDK Singleton for Godot 4.x
## Universal Plug-n-Play bridge supporting both Web export and Editor / Desktop Mock mode.

signal sdk_initialized(data: Dictionary)
signal game_paused
signal game_resumed
signal history_back_requested
signal account_selection_opened
signal account_selection_closed

## If true, automatically mutes AudioServer master bus during ads and platform pause events.
@export var auto_mute_audio: bool = true

## If true, automatically calls LoadingAPI.ready() after successful initialization.
@export var auto_call_game_ready: bool = true

## If true, automatically sets TranslationServer locale to Yandex Games interface language on startup (Requirement 2.14).
@export var auto_apply_locale: bool = true

## If true, automatically initializes SDK in Web exports on startup.
@export var auto_init: bool = true

## If true, automatically pauses the SceneTree (get_tree().paused = true) during platform pause and ads.
@export var auto_pause_tree: bool = false

## True if the game is currently paused by platform events (ad display, tab defocus, modal dialogs).
var is_platform_paused: bool = false

# Sub-modules
var ads: YandexAds
var player: YandexPlayer
var leaderboards: YandexLeaderboards
var payments: YandexPayments
var feedback: YandexFeedback
var shortcut: YandexShortcut
var device: YandexDevice
var environment: YandexEnvironment
var storage: YandexStorage
var remote_config: YandexRemoteConfig
var games: YandexGamesAPI
var clipboard: YandexClipboard
var multiplayer_sessions: YandexMultiplayer

# Internal state
var is_initialized: bool = false
var mock_bridge: YandexMockBridge = null
var _js_bridge: JavaScriptObject = null
var _js_pause_resume_cb: JavaScriptObject = null
var _ad_event_queue: Array[Dictionary] = []
var _is_initializing: bool = false
var _pause_sources: int = 0
var _audio_muted_by_platform: bool = false
var _user_was_muted_before: bool = false

func _ready() -> void:
	_load_project_settings()

	# Instantiate modules
	ads = YandexAds.new(self)
	player = YandexPlayer.new(self)
	leaderboards = YandexLeaderboards.new(self)
	payments = YandexPayments.new(self)
	feedback = YandexFeedback.new(self)
	shortcut = YandexShortcut.new(self)
	device = YandexDevice.new(self)
	environment = YandexEnvironment.new(self)
	storage = YandexStorage.new(self)
	remote_config = YandexRemoteConfig.new(self)
	games = YandexGamesAPI.new(self)
	clipboard = YandexClipboard.new(self)
	multiplayer_sessions = YandexMultiplayer.new(self)

	if not is_web():
		mock_bridge = YandexMockBridge.new()
		# Initialize mock immediately so it's ready in editor
		init()
	else:
		_setup_web_callbacks()
		if auto_init:
			init()

func _load_project_settings() -> void:
	auto_init = bool(ProjectSettings.get_setting("yandex_games/general/auto_init", auto_init))
	auto_call_game_ready = bool(ProjectSettings.get_setting("yandex_games/general/auto_call_game_ready", auto_call_game_ready))
	auto_apply_locale = bool(ProjectSettings.get_setting("yandex_games/general/auto_apply_locale", auto_apply_locale))
	auto_pause_tree = bool(ProjectSettings.get_setting("yandex_games/general/auto_pause_tree", auto_pause_tree))
	auto_mute_audio = bool(ProjectSettings.get_setting("yandex_games/ads/auto_mute_audio", auto_mute_audio))

func is_web() -> bool:
	return OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge")

func _setup_web_callbacks() -> void:
	if not is_web():
		return
	
	_js_pause_resume_cb = JavaScriptBridge.create_callback(_on_js_pause_resume)
	var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
	if bridge:
		bridge.setPauseResumeCallback(_js_pause_resume_cb)

func _js_to_string(js_val: Variant) -> String:
	if js_val == null:
		return ""
	if js_val is String:
		return js_val
	if ClassDB.class_exists("JavaScriptObject") and js_val is JavaScriptObject:
		var js_json: JavaScriptObject = JavaScriptBridge.get_interface("JSON")
		if js_json:
			return str(js_json.stringify(js_val))
	return str(js_val)

func _on_js_pause_resume(args: Array) -> void:
	if args.is_empty():
		return
	var json_str: String = _js_to_string(args[0])
	var json: JSON = JSON.new()
	if json.parse(json_str) == OK and json.data is Dictionary:
		var ev: String = str(json.data.get("event", ""))
		if ev == "pause":
			_on_platform_pause()
		elif ev == "resume":
			_on_platform_resume()
		elif ev == "multiplayer_transaction":
			var d: Dictionary = json.data.get("data", {})
			var opp_id: String = str(d.get("opponentId", ""))
			var txs: Array = d.get("transactions", [])
			multiplayer_sessions.transaction_received.emit(opp_id, txs)
		elif ev == "multiplayer_finish":
			var opp_id: String = str(json.data.get("opponentId", ""))
			multiplayer_sessions.session_finished.emit(opp_id)
		elif ev == "history_back":
			history_back_requested.emit()
		elif ev == "account_selection_opened":
			account_selection_opened.emit()
		elif ev == "account_selection_closed":
			account_selection_closed.emit()

func _request_pause() -> void:
	_pause_sources += 1
	if _pause_sources == 1:
		is_platform_paused = true
		if auto_mute_audio:
			_user_was_muted_before = AudioServer.is_bus_mute(0)
			if not _user_was_muted_before:
				AudioServer.set_bus_mute(0, true)
				_audio_muted_by_platform = true
		if auto_pause_tree:
			get_tree().paused = true
		game_paused.emit()

func _release_pause() -> void:
	_pause_sources = max(0, _pause_sources - 1)
	if _pause_sources == 0:
		is_platform_paused = false
		if auto_mute_audio and _audio_muted_by_platform:
			if not _user_was_muted_before:
				AudioServer.set_bus_mute(0, false)
			_audio_muted_by_platform = false
		if auto_pause_tree:
			get_tree().paused = false
		game_resumed.emit()

func _on_platform_pause() -> void:
	_request_pause()

func _on_platform_resume() -> void:
	_release_pause()

func _on_ad_start() -> void:
	_request_pause()

func _on_ad_end() -> void:
	_release_pause()

## Ensures that SDK is initialized, awaiting completion if already in progress.
func ensure_initialized() -> bool:
	if is_initialized:
		return true
	if _is_initializing:
		while _is_initializing and not is_initialized:
			await get_tree().process_frame
		return is_initialized
	return await init()

## Initializes the Yandex Games SDK.
## Options can contain screen settings (fullscreen, orientation lock).
func init(options: Dictionary = {}) -> bool:
	if is_initialized:
		return true
	if _is_initializing:
		while _is_initializing and not is_initialized:
			await get_tree().process_frame
		return is_initialized

	_is_initializing = true
	var res: Dictionary
	if is_web():
		res = await call_js_async("init", [JSON.stringify(options)])
	else:
		res = mock_bridge.init(options)

	_is_initializing = false

	if res.get("success", false):
		is_initialized = true
		var data: Dictionary = res.get("data", {})
		if data.has("environment"):
			environment._update_env(data.environment)
			if auto_apply_locale:
				var lang: String = environment.get_lang()
				if not lang.is_empty():
					TranslationServer.set_locale(lang)
		if data.has("device"):
			device._update_info(data.device)
		
		sdk_initialized.emit(data)
		
		# Auto-init player profile quietly
		player.init()
		
		if auto_call_game_ready:
			game_ready()
		return true
	return false

# --- Core Lifecycle APIs ---

## Notifies Yandex platform that the game has finished loading assets and is ready. (Mandatory for catalog!)
func game_ready() -> void:
	if is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.loadingReady()
	else:
		mock_bridge.loading_ready()

## Marks the start or resumption of active gameplay (level start, unpause).
func gameplay_start() -> void:
	if is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.gameplayStart()
	else:
		mock_bridge.gameplay_start()

## Marks the stop or pause of gameplay (level finished, menu opened, player died).
func gameplay_stop() -> void:
	if is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.gameplayStop()
	else:
		mock_bridge.gameplay_stop()

## Retrieves synchronized server time in milliseconds.
func get_server_time() -> int:
	if is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			return int(bridge.serverTime())
		return int(Time.get_unix_time_from_system() * 1000.0)
	else:
		return mock_bridge.server_time()

## Checks whether a specific Yandex Games SDK method is supported on current platform.
func is_available_method(method_name: String) -> bool:
	if is_web():
		var res: Dictionary = await call_js_async("isAvailableMethod", [method_name])
		return res.get("available", false)
	else:
		return mock_bridge.is_available_method(method_name)

## Dispatches an SDK event (such as ysdk.EVENTS.EXIT).
func dispatch_event(event_name: String, detail: Dictionary = {}) -> bool:
	if is_web():
		var detail_json: String = JSON.stringify(detail) if not detail.is_empty() else ""
		var res: Dictionary = await call_js_async("dispatchEvent", [event_name, detail_json])
		return res.get("success", false)
	else:
		var res: Dictionary = mock_bridge.dispatch_event(event_name, detail)
		return res.get("success", false)

## Dispatches EXIT event to the platform (required confirmation on Smart TV when player confirms exit).
func dispatch_exit() -> void:
	if is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.dispatchExit(JavaScriptBridge.create_callback(func(_args): pass))
	else:
		mock_bridge.exit()

# --- Quick Facade Shortcuts ---

## Quick shortcut to show an interstitial advertisement.
func show_interstitial() -> Dictionary:
	return await ads.show_interstitial()

## Quick shortcut to show a rewarded video advertisement.
func show_rewarded() -> Dictionary:
	return await ads.show_rewarded()

## Quick shortcut to display sticky banner.
func show_banner() -> Dictionary:
	return await ads.show_banner()

## Quick shortcut to hide sticky banner.
func hide_banner() -> Dictionary:
	return await ads.hide_banner()

# --- Internal JavaScript Async Bridge Helper ---

func call_js_async(method_name: String, args: Array = [], timeout_sec: float = 60.0) -> Dictionary:
	if not is_web():
		return { "success": false, "error": "Not running in Web export" }
	
	var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
	if not bridge:
		return { "success": false, "error": "GodotYandexBridge JS object not found" }
	
	var result_holder: Dictionary = { "completed": false, "data": {} }
	
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(func(cb_args: Array) -> void:
		var raw: String = _js_to_string(cb_args[0]) if not cb_args.is_empty() else ""
		var json: JSON = JSON.new()
		var parsed_data: Dictionary = {}
		if json.parse(raw) == OK and json.data is Dictionary:
			parsed_data = json.data
		else:
			parsed_data = { "success": true, "raw": raw }

		if result_holder.completed:
			_ad_event_queue.append(parsed_data)
		else:
			result_holder.data = parsed_data
			result_holder.completed = true
	)
	
	var call_args: Array = args.duplicate()
	call_args.append(cb)
	
	bridge.callv(method_name, Array(call_args))
	
	var elapsed: float = 0.0
	while not result_holder.completed:
		await get_tree().process_frame
		if timeout_sec > 0.0:
			elapsed += get_process_delta_time()
			if elapsed >= timeout_sec:
				return { "success": false, "error": "Timeout waiting for JS method: %s" % method_name }
	
	return result_holder.data

func _wait_for_next_ad_event(timeout_sec: float = 75.0) -> Dictionary:
	var elapsed: float = 0.0
	while _ad_event_queue.is_empty():
		await get_tree().process_frame
		if timeout_sec > 0.0:
			elapsed += get_process_delta_time()
			if elapsed >= timeout_sec:
				return { "event": "error", "error": "Timeout waiting for ad event" }
	return _ad_event_queue.pop_front()

func _clear_ad_event_queue() -> void:
	_ad_event_queue.clear()

