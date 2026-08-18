@tool
class_name YandexAds
extends RefCounted

## Manages Interstitial, Rewarded Video, and Sticky Banner Advertisements.

signal interstitial_opened
signal interstitial_closed(was_shown: bool)
signal interstitial_failed(error: String)
signal interstitial_offline

signal rewarded_opened
signal rewarded_rewarded
signal rewarded_closed(was_shown: bool)
signal rewarded_failed(error: String)

signal banner_shown
signal banner_hidden
signal banner_status_changed(is_showing: bool, reason: String)

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Shows a full-screen interstitial advertisement.
## Returns a Dictionary: { "success": bool, "was_shown": bool, "error": String }
func show_interstitial() -> Dictionary:
	_core._on_ad_start()
	var result: Dictionary = { "success": false, "was_shown": false, "error": "" }
	
	if _core.is_web():
		var cb_data: Dictionary = await _core.call_js_async("showFullscreenAdv")
		var event: String = str(cb_data.get("event", ""))
		while event != "close" and event != "error" and event != "offline":
			if event == "open":
				interstitial_opened.emit()
			cb_data = await _core._wait_for_next_ad_event()
			event = str(cb_data.get("event", ""))
		
		if event == "close":
			var was_shown: bool = cb_data.get("wasShown", false)
			interstitial_closed.emit(was_shown)
			result.success = true
			result.was_shown = was_shown
		elif event == "offline":
			interstitial_offline.emit()
			result.error = "Offline"
		else:
			var err: String = str(cb_data.get("error", "Ad error"))
			interstitial_failed.emit(err)
			result.error = err
	else:
		# Mock mode
		var ad_events: Array[Dictionary] = []
		var mock_cb: Callable = func(payload: Dictionary) -> void:
			ad_events.append(payload)
			var ev: String = str(payload.get("event", ""))
			if ev == "open":
				interstitial_opened.emit()
			elif ev == "close":
				var was_shown: bool = payload.get("wasShown", true)
				interstitial_closed.emit(was_shown)
		
		await _core.mock_bridge.show_fullscreen_adv(mock_cb)
		result.success = true
		result.was_shown = true
	
	_core._on_ad_end()
	return result

## Shows a rewarded video advertisement.
## Returns a Dictionary: { "success": bool, "rewarded": bool, "was_shown": bool, "error": String }
func show_rewarded() -> Dictionary:
	_core._on_ad_start()
	var result: Dictionary = { "success": false, "rewarded": false, "was_shown": false, "error": "" }
	
	if _core.is_web():
		var cb_data: Dictionary = await _core.call_js_async("showRewardedVideo")
		var event: String = str(cb_data.get("event", ""))
		var got_reward: bool = false
		
		while event != "close" and event != "error":
			if event == "open":
				rewarded_opened.emit()
			elif event == "rewarded":
				got_reward = true
				rewarded_rewarded.emit()
			cb_data = await _core._wait_for_next_ad_event()
			event = str(cb_data.get("event", ""))
		
		if event == "close":
			var was_shown: bool = cb_data.get("wasShown", false)
			rewarded_closed.emit(was_shown)
			result.success = true
			result.rewarded = got_reward
			result.was_shown = was_shown
		else:
			var err: String = str(cb_data.get("error", "Rewarded ad error"))
			rewarded_failed.emit(err)
			result.error = err
	else:
		# Mock mode
		var state: Dictionary = { "got_reward": false }
		var mock_cb: Callable = func(payload: Dictionary) -> void:
			var ev: String = str(payload.get("event", ""))
			if ev == "open":
				rewarded_opened.emit()
			elif ev == "rewarded":
				state.got_reward = true
				rewarded_rewarded.emit()
			elif ev == "close":
				var was_shown: bool = payload.get("wasShown", true)
				rewarded_closed.emit(was_shown)
		
		await _core.mock_bridge.show_rewarded_video(mock_cb)
		result.success = true
		result.rewarded = state.got_reward
		result.was_shown = true
	
	_core._on_ad_end()
	return result

## Fetches the current sticky banner status.
## Returns: { "is_showing": bool, "reason": String }
func get_banner_status() -> Dictionary:
	var response: Dictionary
	if _core.is_web():
		response = await _core.call_js_async("getBannerAdvStatus")
	else:
		response = _core.mock_bridge.get_banner_adv_status()
	
	var is_showing: bool = response.get("stickyAdvIsShowing", false)
	var reason: String = str(response.get("reason", ""))
	banner_status_changed.emit(is_showing, reason)
	return { "is_showing": is_showing, "reason": reason }

## Displays the sticky banner on screen.
func show_banner() -> Dictionary:
	var response: Dictionary
	if _core.is_web():
		response = await _core.call_js_async("showBannerAdv")
	else:
		response = _core.mock_bridge.show_banner_adv()
	
	var is_showing: bool = response.get("stickyAdvIsShowing", false)
	if is_showing:
		banner_shown.emit()
	return response

## Hides the sticky banner from screen.
func hide_banner() -> Dictionary:
	var response: Dictionary
	if _core.is_web():
		response = await _core.call_js_async("hideBannerAdv")
	else:
		response = _core.mock_bridge.hide_banner_adv()
	
	banner_hidden.emit()
	return response
