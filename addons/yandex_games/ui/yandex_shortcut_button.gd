@tool
class_name YandexShortcutButton
extends Button

## Plug-and-play button for installing game shortcut on desktop or mobile home screen.
## Automatically checks canShowPrompt() and hides itself when not supported or already installed.

signal shortcut_prompt_completed(outcome: String)
signal shortcut_check_completed(can_show: bool)

## Automatically checks shortcut installation eligibility on startup and adjusts button visibility.
@export var auto_check_on_ready: bool = true

## Hides the button if shortcut prompt cannot be shown (e.g. already installed or platform unsupported).
@export var hide_when_unsupported: bool = true

## Hides the button immediately after the shortcut prompt is accepted by the player.
@export var hide_after_installed: bool = true

var is_eligible: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	pressed.connect(_on_pressed)

	if auto_check_on_ready:
		check_eligibility()

## Queries Yandex Games SDK whether the shortcut prompt can be shown.
func check_eligibility() -> bool:
	var yg: Node = Engine.get_main_loop().root.get_node_or_null("YandexGames") if Engine.get_main_loop() else null
	if not yg or not yg.get("shortcut"):
		return false

	var shortcut = yg.get("shortcut")
	is_eligible = await shortcut.can_show_prompt()

	shortcut_check_completed.emit(is_eligible)

	if hide_when_unsupported:
		visible = is_eligible

	return is_eligible

func _on_pressed() -> void:
	var yg: Node = Engine.get_main_loop().root.get_node_or_null("YandexGames") if Engine.get_main_loop() else null
	if not yg or not yg.get("shortcut"):
		return

	disabled = true
	var shortcut = yg.get("shortcut")
	var res: Dictionary = await shortcut.show_prompt()
	disabled = false

	var outcome: String = str(res.get("outcome", "rejected"))
	shortcut_prompt_completed.emit(outcome)

	if outcome == "accepted" and hide_after_installed:
		visible = false
