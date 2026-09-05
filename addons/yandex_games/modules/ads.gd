@tool
class_name YandexAds
extends RefCounted

## Manages Interstitial, Rewarded Video, and Sticky Banner Advertisements.

signal interstitial_opened
signal interstitial_closed(was_shown: bool)
signal interstitial_failed(error: String)
signal interstitial_offline
signal interstitial_cooldown_finished

signal rewarded_opened
signal rewarded_rewarded
signal rewarded_closed(was_shown: bool)
signal rewarded_failed(error: String)

signal banner_shown
signal banner_hidden
signal banner_status_changed(is_showing: bool, reason: String)

var _core: Node = null
var cooldown_duration: float = 60.0
var _last_interstitial_time: float = -999999.0
var is_banner_showing: bool = false
var banner_height_pixels: int = 70

func _init(core: Node) -> void:
	_core = core
	cooldown_duration = float(ProjectSettings.get_setting("yandex_games/ads/interstitial_cooldown", 60.0))

## Returns true if enough time has passed since the last interstitial advertisement.
func can_show_interstitial() -> bool:
	return get_time_until_next_interstitial() <= 0.0

## Returns the number of seconds remaining before another interstitial ad can be displayed.
func get_time_until_next_interstitial() -> float:
	var now: float = Time.get_ticks_msec() / 1000.0
	var elapsed: float = now - _last_interstitial_time
	return max(0.0, cooldown_duration - elapsed)

## Shows an interstitial ad only if the cooldown has elapsed (or if ignore_cooldown is true).
func show_interstitial_if_available(ignore_cooldown: bool = false) -> Dictionary:
	if not ignore_cooldown and not can_show_interstitial():
		var remaining := get_time_until_next_interstitial()
		return {
			"success": false,
			"was_shown": false,
			"error": "Interstitial cooldown active (%.1fs remaining)" % remaining
		}
	return await show_interstitial()

## Shows a full-screen interstitial advertisement.
## Returns a Dictionary: { "success": bool, "was_shown": bool, "error": String }
func show_interstitial() -> Dictionary:
	_core._on_ad_start()
	if _core.has_method("_clear_ad_event_queue"):
		_core._clear_ad_event_queue()
		
	var result: Dictionary = { "success": false, "was_shown": false, "error": "" }
	
	if _core.is_web():
		var is_close: Callable = func(ev: String) -> bool: return ev in ["close", "onclose"]
		var is_error: Callable = func(ev: String) -> bool: return ev in ["error", "onerror"]
		var is_open: Callable = func(ev: String) -> bool: return ev in ["open", "onopen"]
		var is_offline: Callable = func(ev: String) -> bool: return ev in ["offline"]

		var cb_data: Dictionary = await _core.call_js_async("showFullscreenAdv")
		var event: String = str(cb_data.get("event", "")).to_lower()
		var is_finished: bool = false

		var handle_event: Callable = func(ev: String, data: Dictionary) -> void:
			if is_open.call(ev):
				interstitial_opened.emit()
			elif is_close.call(ev):
				var was_shown: bool = data.get("wasShown", false)
				result.success = true
				result.was_shown = was_shown
				is_finished = true
			elif is_offline.call(ev):
				interstitial_offline.emit()
				result.error = "Offline"
				is_finished = true
			elif is_error.call(ev):
				result.error = str(data.get("error", "Ad error"))
				interstitial_failed.emit(result.error)
				is_finished = true

		handle_event.call(event, cb_data)

		while not is_finished:
			cb_data = await _core._wait_for_next_ad_event(60.0)
			event = str(cb_data.get("event", "")).to_lower()
			handle_event.call(event, cb_data)
		
		_core._on_ad_end()
		if result.success:
			interstitial_closed.emit(result.was_shown)
	else:
		# Mock mode
		var was_shown_mock: bool = true
		var mock_cb: Callable = func(payload: Dictionary) -> void:
			var ev: String = str(payload.get("event", "")).to_lower()
			if ev in ["open", "onopen"]:
				interstitial_opened.emit()
			elif ev in ["close", "onclose"]:
				was_shown_mock = payload.get("wasShown", true)
		
		await _core.mock_bridge.show_fullscreen_adv(mock_cb)
		_core._on_ad_end()
		result.success = true
		result.was_shown = was_shown_mock
		interstitial_closed.emit(was_shown_mock)
	
	if result.was_shown:
		_last_interstitial_time = Time.get_ticks_msec() / 1000.0
		_schedule_cooldown_timer()

	return result

func _schedule_cooldown_timer() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		var current_time := _last_interstitial_time
		await tree.create_timer(cooldown_duration).timeout
		if _last_interstitial_time == current_time:
			interstitial_cooldown_finished.emit()

## Shows a rewarded video advertisement.
## Returns a Dictionary: { "success": bool, "rewarded": bool, "was_shown": bool, "error": String }
func show_rewarded() -> Dictionary:
	_core._on_ad_start()
	if _core.has_method("_clear_ad_event_queue"):
		_core._clear_ad_event_queue()

	var result: Dictionary = { "success": false, "rewarded": false, "was_shown": false, "error": "" }
	
	if _core.is_web():
		var is_reward: Callable = func(ev: String) -> bool: return ev in ["rewarded", "reward", "onrewarded"]
		var is_close: Callable = func(ev: String) -> bool: return ev in ["close", "onclose"]
		var is_error: Callable = func(ev: String) -> bool: return ev in ["error", "onerror"]
		var is_open: Callable = func(ev: String) -> bool: return ev in ["open", "onopen"]

		var cb_data: Dictionary = await _core.call_js_async("showRewardedVideo")
		var event: String = str(cb_data.get("event", "")).to_lower()
		var got_reward: bool = false
		var was_shown: bool = false
		var is_finished: bool = false

		var handle_event: Callable = func(ev: String, data: Dictionary) -> void:
			if is_open.call(ev):
				rewarded_opened.emit()
			elif is_reward.call(ev):
				if not got_reward:
					got_reward = true
					rewarded_rewarded.emit()
			elif is_close.call(ev):
				was_shown = data.get("wasShown", true)
				is_finished = true
			elif is_error.call(ev):
				result.error = str(data.get("error", "Rewarded ad error"))
				rewarded_failed.emit(result.error)
				is_finished = true

		handle_event.call(event, cb_data)

		while not is_finished:
			cb_data = await _core._wait_for_next_ad_event(75.0)
			event = str(cb_data.get("event", "")).to_lower()
			handle_event.call(event, cb_data)

		# Обработка опоздавших событий rewarded (race condition в SDK Яндекса)
		while not _core._ad_event_queue.is_empty():
			var late: Dictionary = _core._ad_event_queue.pop_front()
			var late_event: String = str(late.get("event", "")).to_lower()
			if is_reward.call(late_event) and not got_reward:
				got_reward = true
				rewarded_rewarded.emit()

		_core._on_ad_end()

		# Корректное выставление результата и отправка сигнала закрытия
		if result.error.is_empty():
			result.success = true
			result.rewarded = got_reward
			result.was_shown = was_shown
			rewarded_closed.emit(was_shown)
		else:
			result.success = false
	else:
		# Mock mode
		var state: Dictionary = { "got_reward": false, "was_shown": false }
		var mock_cb: Callable = func(payload: Dictionary) -> void:
			var ev: String = str(payload.get("event", "")).to_lower()
			if ev in ["open", "onopen"]:
				rewarded_opened.emit()
			elif ev in ["rewarded", "reward", "onrewarded"]:
				state.got_reward = true
				rewarded_rewarded.emit()
			elif ev in ["close", "onclose"]:
				state.was_shown = payload.get("wasShown", true)
		
		await _core.mock_bridge.show_rewarded_video(mock_cb)
		_core._on_ad_end()
		result.success = true
		result.rewarded = state.got_reward
		result.was_shown = state.was_shown
		rewarded_closed.emit(state.was_shown)
	
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
	is_banner_showing = is_showing
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
	is_banner_showing = is_showing
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
	
	is_banner_showing = false
	banner_hidden.emit()
	return response
