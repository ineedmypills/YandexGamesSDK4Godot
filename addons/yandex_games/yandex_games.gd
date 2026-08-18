@tool
extends Node

## Yandex Games SDK Singleton for Godot 4.x
## Universal Plug-n-Play bridge supporting both Web export and Editor / Desktop Mock mode.

signal sdk_initialized(data: Dictionary)
signal game_paused
signal game_resumed

## If true, automatically mutes AudioServer master bus during ads and platform pause events.
@export var auto_mute_audio: bool = true

## If true, automatically calls LoadingAPI.ready() after successful initialization.
@export var auto_call_game_ready: bool = true

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
var multiplayer: YandexMultiplayer

# Internal state
var is_initialized: bool = false
var mock_bridge: YandexMockBridge = null
var _js_bridge = null
var _js_pause_resume_cb = null
var _ad_event_queue: Array = []

func _ready() -> void:
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
	multiplayer = YandexMultiplayer.new(self)

	if not is_web():
		mock_bridge = YandexMockBridge.new()
		# Initialize mock immediately so it's ready in editor
		init()
	else:
		_setup_web_callbacks()

func is_web() -> bool:
	return OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge")

func _setup_web_callbacks() -> void:
	if not is_web():
		return
	
	_js_pause_resume_cb = JavaScriptBridge.create_callback(_on_js_pause_resume)
	var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
	if bridge:
		bridge.setPauseResumeCallback(_js_pause_resume_cb)

func _on_js_pause_resume(args: Array) -> void:
	if args.is_empty():
		return
	var json_str = str(args[0])
	var json = JSON.new()
	if json.parse(json_str) == OK and json.data is Dictionary:
		var ev = json.data.get("event", "")
		if ev == "pause":
			_on_platform_pause()
		elif ev == "resume":
			_on_platform_resume()
		elif ev == "multiplayer_transaction":
			var d = json.data.get("data", {})
			var opp_id = str(d.get("opponentId", ""))
			var txs = d.get("transactions", [])
			multiplayer.transaction_received.emit(opp_id, txs)
		elif ev == "multiplayer_finish":
			var opp_id = str(json.data.get("opponentId", ""))
			multiplayer.session_finished.emit(opp_id)

func _on_platform_pause() -> void:
	if auto_mute_audio:
		AudioServer.set_bus_mute(0, true)
	game_paused.emit()

func _on_platform_resume() -> void:
	if auto_mute_audio:
		AudioServer.set_bus_mute(0, false)
	game_resumed.emit()

func _on_ad_start() -> void:
	if auto_mute_audio:
		AudioServer.set_bus_mute(0, true)

func _on_ad_end() -> void:
	if auto_mute_audio:
		AudioServer.set_bus_mute(0, false)

## Initializes the Yandex Games SDK.
## Options can contain screen settings (fullscreen, orientation lock).
func init(options: Dictionary = {}) -> bool:
	if is_initialized:
		return true

	var res: Dictionary
	if is_web():
		res = await call_js_async("init", [JSON.stringify(options)])
	else:
		res = mock_bridge.init(options)

	if res.get("success", false):
		is_initialized = true
		var data = res.get("data", {})
		if data.has("environment"):
			environment._update_env(data.environment)
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
		var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.loadingReady()
	else:
		mock_bridge.loading_ready()

## Marks the start or resumption of active gameplay (level start, unpause).
func gameplay_start() -> void:
	if is_web():
		var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.gameplayStart()
	else:
		mock_bridge.gameplay_start()

## Marks the stop or pause of gameplay (level finished, menu opened, player died).
func gameplay_stop() -> void:
	if is_web():
		var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.gameplayStop()
	else:
		mock_bridge.gameplay_stop()

## Retrieves synchronized server time in milliseconds.
func get_server_time() -> int:
	if is_web():
		var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			return int(bridge.serverTime())
		return int(Time.get_unix_time_from_system() * 1000.0)
	else:
		return mock_bridge.server_time()

## Checks whether a specific Yandex Games SDK method is supported on current platform.
func is_available_method(method_name: String) -> bool:
	if is_web():
		var res = await call_js_async("isAvailableMethod", [method_name])
		return res.get("available", false)
	else:
		return mock_bridge.is_available_method(method_name)

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

func call_js_async(method_name: String, args: Array = []) -> Dictionary:
	if not is_web():
		return { "success": false, "error": "Not running in Web export" }
	
	var bridge = JavaScriptBridge.get_interface("GodotYandexBridge")
	if not bridge:
		return { "success": false, "error": "GodotYandexBridge JS object not found" }
	
	var result_holder = { "completed": false, "data": {} }
	
	var cb = JavaScriptBridge.create_callback(func(cb_args: Array):
		var raw = ""
		if not cb_args.is_empty():
			raw = str(cb_args[0])
		var json = JSON.new()
		var parsed_data = {}
		if json.parse(raw) == OK and json.data is Dictionary:
			parsed_data = json.data
		else:
			parsed_data = { "success": true, "raw": raw }
		
		result_holder.data = parsed_data
		result_holder.completed = true
		_ad_event_queue.append(parsed_data)
	)
	
	var call_args = args.duplicate()
	call_args.append(cb)
	
	bridge.callv(method_name, Array(call_args))
	
	while not result_holder.completed:
		await get_tree().process_frame
	
	return result_holder.data

func _wait_for_next_ad_event() -> Dictionary:
	while _ad_event_queue.is_empty():
		await get_tree().process_frame
	return _ad_event_queue.pop_front()

