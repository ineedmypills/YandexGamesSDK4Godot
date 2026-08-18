@tool
class_name YandexEnvironment
extends RefCounted

## Provides Environment parameters: language, top-level domain (TLD), App ID, and payload.

var _core: Node = null
var _env: Dictionary = {
	"app": { "id": "" },
	"browser": { "lang": "ru" },
	"i18n": { "lang": "ru", "tld": "ru" },
	"payload": "",
	"fullscreen": false
}

func _init(core: Node) -> void:
	_core = core

func _update_env(env: Dictionary) -> void:
	_env = env

## Returns application ID in Yandex Games catalog.
func get_app_id() -> String:
	return str(_env.get("app", {}).get("id", ""))

## Returns browser language code (e.g. 'ru-RU', 'en-US').
func get_browser_lang() -> String:
	return str(_env.get("browser", {}).get("lang", "ru"))

## Returns interface language code according to Yandex Games locale (e.g. 'ru', 'en', 'tr', 'de', 'es').
func get_lang() -> String:
	return str(_env.get("i18n", {}).get("lang", "ru"))

## Returns top-level domain where the game is running (e.g. 'ru', 'com', 'by', 'kz', 'uz').
func get_tld() -> String:
	return str(_env.get("i18n", {}).get("tld", "ru"))

## Returns launch payload string passed in URL parameters (e.g. referral tags, invite tokens).
func get_payload() -> String:
	return str(_env.get("payload", ""))

## Returns complete dictionary with all environment variables.
func get_all() -> Dictionary:
	return _env.duplicate(true)
