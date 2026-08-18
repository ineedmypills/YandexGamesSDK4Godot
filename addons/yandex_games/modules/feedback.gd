@tool
class_name YandexFeedback
extends RefCounted

## Manages Game Ratings and Feedback Reviews.

signal review_requested(feedback_sent: bool)

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Checks if the player is eligible to leave a review.
## Returns: { "value": bool, "reason": String } (e.g. 'NO_AUTH', 'GAME_RATED', 'REVIEW_ALREADY_REQUESTED')
func can_review() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("canReview")
	else:
		res = _core.mock_bridge.can_review()
	return res.get("data", { "value": false, "reason": "UNKNOWN" }) if res.get("success", false) else { "value": false, "reason": "UNKNOWN" }

## Opens the native Yandex review and rating prompt.
## Returns: { "value": bool, "feedback_sent": bool }
func request_review() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("requestReview")
	else:
		res = await _core.mock_bridge.request_review()
	
	var data: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	var sent: bool = data.get("feedbackSent", false)
	review_requested.emit(sent)
	return { "value": data.get("value", false), "feedback_sent": sent }
