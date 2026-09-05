@tool
class_name YandexReviewButton
extends Button

## Plug-and-play button for requesting game reviews and ratings on Yandex Games.
## Automatically queries canReview() and hides itself when not supported or already rated.

signal review_completed(feedback_sent: bool)
signal review_check_completed(can_review: bool, reason: String)

## Automatically checks review eligibility on startup and adjusts button visibility.
@export var auto_check_on_ready: bool = true

## Hides the button if player cannot review (e.g. already reviewed, not authorized, or platform unsupported).
@export var hide_when_unsupported: bool = true

## Hides the button immediately after a review has been successfully submitted.
@export var hide_after_reviewed: bool = true

var is_eligible: bool = true

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	pressed.connect(_on_pressed)

	if auto_check_on_ready:
		check_eligibility()

## Queries Yandex Games SDK whether the current player can review the game.
func check_eligibility() -> bool:
	var yg: Node = Engine.get_main_loop().root.get_node_or_null("YandexGames") if Engine.get_main_loop() else null
	if not yg or not yg.get("feedback"):
		return false

	var feedback = yg.get("feedback")
	var res: Dictionary = await feedback.can_review()
	is_eligible = bool(res.get("value", false))
	var reason: String = str(res.get("reason", ""))

	review_check_completed.emit(is_eligible, reason)

	if hide_when_unsupported:
		visible = is_eligible

	return is_eligible

func _on_pressed() -> void:
	var yg: Node = Engine.get_main_loop().root.get_node_or_null("YandexGames") if Engine.get_main_loop() else null
	if not yg or not yg.get("feedback"):
		return

	disabled = true
	var feedback = yg.get("feedback")
	var res: Dictionary = await feedback.request_review()
	disabled = false

	var sent: bool = bool(res.get("feedback_sent", false))
	review_completed.emit(sent)

	if sent and hide_after_reviewed:
		visible = false
