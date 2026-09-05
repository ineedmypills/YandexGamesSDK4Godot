@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "YandexGames"
const AUTOLOAD_PATH: String = "res://addons/yandex_games/yandex_games.gd"
const _PRESETS_PATH: String = "res://export_presets.cfg"
const _TEMPLATE_PATH: String = "res://addons/yandex_games/templates/yandex_template.html"

var _export_plugin: YandexGamesExportPlugin = null

func _enter_tree() -> void:
	_setup_project_settings()
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_export_plugin = YandexGamesExportPlugin.new()
	add_export_plugin(_export_plugin)
	_ensure_web_preset()
	
	add_tool_menu_item("Yandex Games: Auto-Configure Web Preset", _on_configure_preset)
	add_tool_menu_item("Yandex Games: Package Web Export to Yandex ZIP", _on_package_zip)
	add_tool_menu_item("Yandex Games: Reset Mock Data", _on_reset_mock_data)
	add_tool_menu_item("Yandex Games: Copy Dev Proxy Command (Dev Mode)", _on_copy_dev_proxy_cmd)
	add_tool_menu_item("Yandex Games: Copy Dev Proxy Command (Prod Mode)", _on_copy_prod_proxy_cmd)
	add_tool_menu_item("Yandex Games: Copy Manual Local Server Draft URL", _on_copy_draft_url)
	add_tool_menu_item("Yandex Games: Create purchases-catalog.json", _on_create_catalog)
	add_tool_menu_item("Yandex Games: Open Documentation & Console", _on_open_docs)

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_tool_menu_item("Yandex Games: Auto-Configure Web Preset")
	remove_tool_menu_item("Yandex Games: Package Web Export to Yandex ZIP")
	remove_tool_menu_item("Yandex Games: Reset Mock Data")
	remove_tool_menu_item("Yandex Games: Copy Dev Proxy Command (Dev Mode)")
	remove_tool_menu_item("Yandex Games: Copy Dev Proxy Command (Prod Mode)")
	remove_tool_menu_item("Yandex Games: Copy Manual Local Server Draft URL")
	remove_tool_menu_item("Yandex Games: Create purchases-catalog.json")
	remove_tool_menu_item("Yandex Games: Open Documentation & Console")
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null

func _setup_project_settings() -> void:
	_add_setting("yandex_games/general/auto_init", true, TYPE_BOOL)
	_add_setting("yandex_games/general/auto_call_game_ready", true, TYPE_BOOL)
	_add_setting("yandex_games/general/auto_apply_locale", true, TYPE_BOOL)
	_add_setting("yandex_games/general/auto_pause_tree", false, TYPE_BOOL)
	_add_setting("yandex_games/ads/auto_mute_audio", true, TYPE_BOOL)
	_add_setting("yandex_games/ads/interstitial_cooldown", 60.0, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,300,1")
	_add_setting("yandex_games/payments/auto_check_unconsumed", true, TYPE_BOOL)
	_add_setting("yandex_games/mock/player_name", "Test Player (Editor)", TYPE_STRING)
	_add_setting("yandex_games/mock/player_unique_id", "mock_player_12345", TYPE_STRING)
	_add_setting("yandex_games/mock/is_authorized", true, TYPE_BOOL)

func _add_setting(p_name: String, p_default: Variant, p_type: int, p_hint: int = PROPERTY_HINT_NONE, p_hint_string: String = "") -> void:
	if not ProjectSettings.has_setting(p_name):
		ProjectSettings.set_setting(p_name, p_default)
	ProjectSettings.set_initial_value(p_name, p_default)
	var info: Dictionary = {
		"name": p_name,
		"type": p_type,
		"hint": p_hint,
		"hint_string": p_hint_string
	}
	ProjectSettings.add_property_info(info)

func _on_configure_preset() -> void:
	var res := YandexGamesExportPlugin.configure_web_presets(_PRESETS_PATH)
	if res.get("success", false):
		print_rich("[color=green][YandexGames][/color] %s" % res.get("message", "Web presets configured."))
	else:
		printerr("[YandexGames] Preset configuration failed: %s" % res.get("message", "Unknown error"))

func _on_package_zip() -> void:
	var source_candidates: Array[String] = [
		"res://build/web",
		"res://export/web",
		"res://build",
		"res://export"
	]
	var found_dir := ""
	for c in source_candidates:
		var p := ProjectSettings.globalize_path(c)
		if DirAccess.dir_exists_absolute(p) and FileAccess.file_exists(p.path_join("index.html")):
			found_dir = c
			break
	
	if found_dir.is_empty():
		printerr("[YandexGames] Could not find exported Web build containing index.html in standard folders (res://build/web, res://export/web). Export your project first!")
		return
	
	var res := YandexGamesExportPlugin.package_to_yandex_zip(found_dir)
	if res.get("success", false):
		print_rich("[color=green][YandexGames][/color] Successfully packaged %d files into Yandex-compliant ZIP:\n[color=cyan]%s[/color] (%.2f KB)" % [
			res.get("files_count", 0),
			res.get("zip_path", ""),
			float(res.get("size_bytes", 0)) / 1024.0
		])
	else:
		printerr("[YandexGames] ZIP packaging failed: %s" % res.get("error", "Unknown error"))

func _on_reset_mock_data() -> void:
	var mock_file: String = "user://yandex_mock_data.json"
	if FileAccess.file_exists(mock_file):
		var dir := DirAccess.open("user://")
		if dir and dir.remove("yandex_mock_data.json") == OK:
			print_rich("[color=green][YandexGames][/color] Mock storage (%s) has been successfully reset." % mock_file)
		else:
			printerr("[YandexGames] Failed to remove %s" % mock_file)
	else:
		print("[YandexGames] No mock storage file found (%s)." % mock_file)

func _on_open_docs() -> void:
	OS.shell_open("https://yandex.ru/dev/games/doc/ru/")

func _on_copy_dev_proxy_cmd() -> void:
	var cmd: String = "npx @yandex-games/sdk-dev-proxy -p ./build/web --dev-mode=true"
	DisplayServer.clipboard_set(cmd)
	print_rich("[color=green][YandexGames][/color] Copied dev-proxy command to clipboard:\n[color=cyan]%s[/color]\nRun this in terminal to test your web export with browser mocks." % cmd)

func _on_copy_prod_proxy_cmd() -> void:
	var cmd: String = "npx @yandex-games/sdk-dev-proxy -p ./build/web --app-id=<YOUR_APP_ID>"
	DisplayServer.clipboard_set(cmd)
	print_rich("[color=green][YandexGames][/color] Copied dev-proxy prod command to clipboard:\n[color=cyan]%s[/color]\nReplace <YOUR_APP_ID> with your game draft ID from Yandex Console." % cmd)

func _on_copy_draft_url() -> void:
	var url: String = "https://yandex.ru/games/app/<YOUR_APP_ID>?draft=true&game_url=http://localhost:8060&debug-mode=16"
	DisplayServer.clipboard_set(url)
	print_rich("[color=green][YandexGames][/color] Copied Manual Local Server draft URL to clipboard:\n[color=cyan]%s[/color]\nReplace <YOUR_APP_ID> with your game ID and adjust port if needed." % url)

func _on_create_catalog() -> void:
	var path: String = "res://purchases-catalog.json"
	if FileAccess.file_exists(path):
		print("[YandexGames] %s already exists in project root." % path)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		if _export_plugin:
			f.store_string(_export_plugin._get_default_catalog_json())
		print_rich("[color=green][YandexGames][/color] Created [b]%s[/b] for in-app purchase catalog emulation in local dev mode." % path)

func _ensure_web_preset() -> void:
	YandexGamesExportPlugin.configure_web_presets(_PRESETS_PATH)


