@tool
class_name YandexDevice
extends RefCounted

## Provides information about player device and handles screen / fullscreen mode.

signal fullscreen_changed(is_fullscreen: bool)

var _core: Node = null
var _info: Dictionary = {
	"type": "desktop",
	"isMobile": false,
	"isTablet": false,
	"isDesktop": true,
	"isTV": false
}

func _init(core: Node) -> void:
	_core = core

func _update_info(info: Dictionary) -> void:
	_info = info

## Returns device type string: 'desktop', 'mobile', 'tablet', or 'tv'.
func get_type() -> String:
	return str(_info.get("type", "desktop"))

## Returns true if running on a mobile smartphone.
func is_mobile() -> bool:
	return _info.get("isMobile", false)

## Returns true if running on a tablet device.
func is_tablet() -> bool:
	return _info.get("isTablet", false)

## Returns true if running on a desktop computer.
func is_desktop() -> bool:
	return _info.get("isDesktop", true)

## Returns true if running on a Smart TV.
func is_tv() -> bool:
	return _info.get("isTV", false)

## Returns true if game is currently in browser fullscreen mode.
func is_fullscreen() -> bool:
	if _core.is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			return bridge.fullscreenStatus()
		return false
	else:
		return _core.mock_bridge.fullscreen_status()

## Requests browser fullscreen mode.
func request_fullscreen() -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("fullscreenRequest")
	else:
		res = _core.mock_bridge.fullscreen_request()
	
	var ok: bool = res.get("success", false)
	if ok:
		fullscreen_changed.emit(true)
	return ok

## Exits browser fullscreen mode.
func exit_fullscreen() -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("fullscreenExit")
	else:
		res = _core.mock_bridge.fullscreen_exit()
	
	var ok: bool = res.get("success", false)
	if ok:
		fullscreen_changed.emit(false)
	return ok

## Returns current screen orientation ("portrait" or "landscape").
func get_orientation() -> String:
	if _core.is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			return str(bridge.screenOrientationGet())
		return "landscape"
	else:
		return _core.mock_bridge.screen_orientation_get()

## Requests setting screen orientation ("portrait" or "landscape").
func set_orientation(orientation: String) -> bool:
	if _core.is_web():
		var res: Dictionary = await _core.call_js_async("screenOrientationSet", [orientation])
		return res.get("success", false)
	else:
		return _core.mock_bridge.screen_orientation_set(orientation).get("success", false)

