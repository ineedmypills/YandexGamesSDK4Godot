@tool
class_name YandexClipboard
extends RefCounted

## System and SDK Clipboard helper.

var _core = null

func _init(core) -> void:
	_core = core

## Copies text to system clipboard.
func write_text(text: String) -> bool:
	if _core.is_web():
		var res = await _core.call_js_async("clipboardWriteText", [text])
		return res.get("success", false)
	else:
		return _core.mock_bridge.clipboard_write_text(text).get("success", false)
