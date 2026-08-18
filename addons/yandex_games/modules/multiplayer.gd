@tool
class_name YandexMultiplayer
extends RefCounted

## Manages Asynchronous Multiplayer Sessions (ysdk.multiplayer.sessions).
## Allows recording player actions as ghost/replay timelines and playing against other players' sessions.

signal transaction_received(opponent_id: String, transactions: Array[Dictionary])
signal session_finished(opponent_id: String)

var _core: Node = null

func _init(core: Node) -> void:
	_core = core

## Initializes asynchronous multiplayer sessions and fetches opponent replays.
## Options:
## - count: int (number of opponent sessions to fetch, up to 10)
## - isEventBased: bool (if true, events are automatically dispatched via signals)
## - maxOpponentTurnTime: int (in milliseconds)
## - meta: { "meta1": { "min": 0, "max": 1000 }, ... }
func init_sessions(options: Dictionary) -> Array[Dictionary]:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("multiplayerInitSessions", [JSON.stringify(options)])
		var sessions: Array[Dictionary] = []
		if res.get("success", false):
			for item: Dictionary in res.get("data", []):
				sessions.append(item)
		return sessions
	else:
		return _core.mock_bridge.multiplayer_init_sessions(options)

## Commits a transaction / key action event to current session timeline.
## Example payload: { "x": 10.5, "y": 20.0, "action": "jump" }
func commit(payload: Dictionary) -> void:
	if _core.is_web():
		var bridge: JavaScriptObject = JavaScriptBridge.get_interface("GodotYandexBridge")
		if bridge:
			bridge.multiplayerCommit(JSON.stringify(payload))
	else:
		_core.mock_bridge.multiplayer_commit(payload)

## Saves and publishes the recorded timeline to the server at the end of the session.
## Meta: Dictionary of metadata filters e.g. { "meta1": score, "meta2": level }
func push(meta: Dictionary) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("multiplayerPush", [JSON.stringify(meta)])
	else:
		res = _core.mock_bridge.multiplayer_push(meta)
	return res.get("success", false)
