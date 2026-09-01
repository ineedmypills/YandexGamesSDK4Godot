@tool
class_name YandexGamesExportPlugin
extends EditorExportPlugin

const _TEMPLATE_PATH: String = "res://addons/yandex_games/templates/yandex_template.html"

func _get_name() -> String:
	return "YandexGamesSDK"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_name() == "Web"

func _get_export_option_warning(platform: EditorExportPlatform, option: String) -> String:
	if option == "html/custom_html_shell":
		var current: String = str(get_option("html/custom_html_shell"))
		if current != _TEMPLATE_PATH:
			return "Yandex Games SDK requires this template.\nSet to: %s" % _TEMPLATE_PATH
	return ""

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if not features.has("web"):
		return
	var shell: String = str(get_option("html/custom_html_shell"))
	if shell != _TEMPLATE_PATH:
		push_error(
			"[YandexGames] Custom HTML Shell is not set to the Yandex template.\n" +
			"Go to Project → Export → Web → Options → Custom HTML Shell and select:\n" +
			_TEMPLATE_PATH
		)
