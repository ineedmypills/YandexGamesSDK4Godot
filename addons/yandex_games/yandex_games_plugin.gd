@tool
extends EditorPlugin

const AUTOLOAD_NAME = "YandexGames"
const AUTOLOAD_PATH = "res://addons/yandex_games/yandex_games.gd"

var _export_plugin: YandexGamesExportPlugin = null

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	_export_plugin = YandexGamesExportPlugin.new()
	add_export_plugin(_export_plugin)
	print("[YandexGames Plugin] Enabled and registered '%s' autoload." % AUTOLOAD_NAME)

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null
	print("[YandexGames Plugin] Disabled.")
