@tool
class_name YandexShortcut
extends RefCounted

## Manages Home Screen / Desktop Shortcut Prompts.

signal prompt_shown(outcome: String)

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Checks if shortcut installation prompt can be shown on current platform/browser.
func can_show_prompt() -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("canShowPrompt")
	else:
		res = _core.mock_bridge.can_show_prompt()
	
	var data: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	return data.get("canShow", false)

## Shows the shortcut installation prompt to the player.
## Returns: { "outcome": "accepted" | "rejected" }
func show_prompt() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("showPrompt")
	else:
		res = await _core.mock_bridge.show_prompt()
	
	var data: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	var outcome: String = str(data.get("outcome", "rejected"))
	prompt_shown.emit(outcome)
	return { "outcome": outcome }
