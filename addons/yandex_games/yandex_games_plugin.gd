@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "YandexGames"
const AUTOLOAD_PATH: String = "res://addons/yandex_games/yandex_games.gd"
const _PRESETS_PATH: String = "res://export_presets.cfg"
const _TEMPLATE_PATH: String = "res://addons/yandex_games/templates/yandex_template.html"

var _export_plugin: YandexGamesExportPlugin = null

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_export_plugin = YandexGamesExportPlugin.new()
	add_export_plugin(_export_plugin)
	_ensure_web_preset()

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null

func _ensure_web_preset() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_PRESETS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		return

	for section in cfg.get_sections():
		if cfg.get_value(section, "platform", "") == "Web":
			return

	var sections := cfg.get_sections()
	var idx := 0
	for s in sections:
		var n := s.trim_prefix("preset.")
		if n.is_valid_int():
			idx = max(idx, n.to_int() + 1)

	var section := "preset.%d" % idx
	cfg.set_value(section, "name", "Web (Yandex Games)")
	cfg.set_value(section, "platform", "Web")
	cfg.set_value(section, "runnable", true)
	cfg.set_value(section, "advanced_export", false)
	cfg.set_value(section, "dedicated_server", false)
	cfg.set_value(section, "export_filter", "all_resources")
	cfg.set_value(section, "include_filter", "")
	cfg.set_value(section, "exclude_filter", "")
	cfg.set_value(section, "export_path", "")
	cfg.set_value(section, "encryption_include_filters", "")
	cfg.set_value(section, "encryption_exclude_filters", "")
	cfg.set_value(section, "encrypt_pck", false)
	cfg.set_value(section, "encrypt_directory", false)

	var options_section := "preset.%d.options" % idx
	cfg.set_value(options_section, "html/custom_html_shell", _TEMPLATE_PATH)

	if cfg.save(_PRESETS_PATH) == OK:
		print("[YandexGames] Created Web export preset with Yandex template. Open Project → Export to verify.")

