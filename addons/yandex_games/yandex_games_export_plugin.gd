@tool
class_name YandexGamesExportPlugin
extends EditorExportPlugin

func _get_name() -> String:
	return "YandexGamesSDK"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if features.has("web"):
		print("[YandexGamesExportPlugin] Preparing Web export for Yandex Games...")
