@tool
class_name YandexPlayer
extends RefCounted

## Manages Player Profile, Authentication, Cloud Saves, and Stats.

signal authorized(player_info: Dictionary)
signal auth_failed(error: String)
signal data_loaded(data: Dictionary)
signal data_saved
signal stats_loaded(stats: Dictionary)
signal stats_saved

var _core: Node = null
var _info: Dictionary = {
	"isAuthorized": false,
	"uniqueId": "",
	"name": "",
	"photoSmall": "",
	"photoMedium": "",
	"photoLarge": "",
	"payingStatus": ""
}

func _init(core: Node) -> void:
	_core = core

## Initializes the Player object with optional parameters (e.g. scopes, signed).
func init(options: Dictionary = {}) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("initPlayer", [JSON.stringify(options)])
	else:
		res = _core.mock_bridge.init_player(options)
	
	if res.get("success", false):
		_info = res.get("data", {})
		if is_authorized():
			authorized.emit(_info)
	else:
		auth_failed.emit(str(res.get("error", "Player init failed")))
	return _info

## Opens the native Yandex Games authorization popup dialog.
func open_auth_dialog() -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("openAuthDialog", [], 300.0)
	else:
		res = await _core.mock_bridge.open_auth_dialog()
	
	if res.get("success", false):
		_info = res.get("data", {})
		if is_authorized():
			authorized.emit(_info)
	else:
		auth_failed.emit(str(res.get("error", "Auth dialog failed")))
	return _info

## Returns true if the current player is authorized via Yandex ID.
func is_authorized() -> bool:
	return _info.get("isAuthorized", false)

## Returns the unique permanent identifier of the player.
func get_id() -> String:
	return str(_info.get("uniqueId", ""))

## Returns the public nickname/name of the player.
func get_name() -> String:
	return str(_info.get("name", ""))

## Returns the player's avatar photo URL ("small", "medium", or "large").
func get_photo(size: String = "medium") -> String:
	match size.to_lower():
		"small":
			return str(_info.get("photoSmall", ""))
		"large":
			return str(_info.get("photoLarge", ""))
		_:
			return str(_info.get("photoMedium", ""))

var _avatar_cache: Dictionary = {}

## Loads the player's avatar photo as a Texture2D asynchronously.
## If offline or in editor mock mode, generates a procedural circular avatar.
func get_avatar_texture(size: String = "medium") -> Texture2D:
	var url: String = get_photo(size)
	return await load_texture_from_url(url, get_name())

## Loads an image texture from an HTTP/HTTPS URL with caching and procedural fallback.
func load_texture_from_url(url: String, fallback_text: String = "P") -> Texture2D:
	if url.is_empty():
		return _generate_procedural_avatar(fallback_text)
	
	if _avatar_cache.has(url):
		return _avatar_cache[url]
	
	# In mock mode or offline, use procedural avatar generator
	if not _core.is_web() and (url.begins_with("mock://") or "yandex.net/get-yapic/0/0-0" in url or not url.begins_with("http")):
		var mock_tex := _generate_procedural_avatar(fallback_text)
		_avatar_cache[url] = mock_tex
		return mock_tex

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return _generate_procedural_avatar(fallback_text)

	var http: HTTPRequest = HTTPRequest.new()
	tree.root.add_child(http)
	
	var err := http.request(url)
	if err != OK:
		http.queue_free()
		return _generate_procedural_avatar(fallback_text)
	
	var result: Array = await http.request_completed
	http.queue_free()
	
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]
	
	if response_code == 200 and not body.is_empty():
		var image: Image = Image.new()
		var img_err := image.load_png_from_buffer(body)
		if img_err != OK:
			img_err = image.load_jpg_from_buffer(body)
		if img_err != OK:
			img_err = image.load_webp_from_buffer(body)
		
		if img_err == OK:
			var tex: ImageTexture = ImageTexture.create_from_image(image)
			_avatar_cache[url] = tex
			return tex
	
	var fallback := _generate_procedural_avatar(fallback_text)
	_avatar_cache[url] = fallback
	return fallback

func _generate_procedural_avatar(label: String = "P") -> Texture2D:
	var width := 128
	var height := 128
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	var hash_val := absi(label.hash())
	var hue := fmod(float(hash_val % 360) / 360.0, 1.0)
	var bg_color := Color.from_hsv(hue, 0.65, 0.75, 1.0)
	var center := Vector2(width / 2.0, height / 2.0)
	var radius := float(width / 2.0 - 2.0)
	
	for y in range(height):
		for x in range(width):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var head_center := Vector2(center.x, center.y - 12.0)
				var head_radius := 24.0
				var body_center := Vector2(center.x, center.y + 44.0)
				var body_radius := 40.0
				if Vector2(x, y).distance_to(head_center) <= head_radius or Vector2(x, y).distance_to(body_center) <= body_radius:
					img.set_pixel(x, y, Color.WHITE)
				else:
					img.set_pixel(x, y, bg_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(img)

## Returns player paying status ("paying" or "").
func get_paying_status() -> String:
	return str(_info.get("payingStatus", ""))

## Returns cryptographic signature for backend validation if initialized with signed: true.
func get_signature() -> String:
	return str(_info.get("signature", ""))

## Returns user IDs across other games by the same developer.
func get_ids_per_game() -> Array[Dictionary]:
	if _core.is_web():
		var res: Dictionary = await _core.call_js_async("getPlayerIDsPerGame")
		if res.get("success", false):
			var list: Array[Dictionary] = []
			for item: Dictionary in res.get("data", []):
				list.append(item)
			return list
		return []
	else:
		return _core.mock_bridge.get_player_ids_per_game()

## Retrieves in-game data (cloud save). Pass an Array of String keys or null to retrieve all.
func get_data(keys: Variant = null) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		var keys_json: String = JSON.stringify(keys) if keys != null else ""
		res = await _core.call_js_async("getPlayerData", [keys_json])
	else:
		res = _core.mock_bridge.get_player_data(keys)
	
	var data: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	data_loaded.emit(data)
	return data

## Saves in-game data to the cloud. Set flush to true for immediate synchronization.
func set_data(data: Dictionary, flush: bool = false) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("setPlayerData", [JSON.stringify(data), flush])
	else:
		res = _core.mock_bridge.set_player_data(data, flush)
	
	var ok: bool = res.get("success", false)
	if ok:
		data_saved.emit()
	return ok

## Retrieves numeric player statistics. Pass an Array of String keys or null for all stats.
func get_stats(keys: Variant = null) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		var keys_json: String = JSON.stringify(keys) if keys != null else ""
		res = await _core.call_js_async("getPlayerStats", [keys_json])
	else:
		res = _core.mock_bridge.get_player_stats(keys)
	
	var stats: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	stats_loaded.emit(stats)
	return stats

## Sets numeric player statistics in cloud.
func set_stats(stats: Dictionary) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("setPlayerStats", [JSON.stringify(stats)])
	else:
		res = _core.mock_bridge.set_player_stats(stats)
	
	var ok: bool = res.get("success", false)
	if ok:
		stats_saved.emit()
	return ok

## Atomically increments numeric stats in cloud.
## Example: increment_stats({ "coins": 50, "levels_completed": 1 })
func increment_stats(increments: Dictionary) -> Dictionary:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("incrementPlayerStats", [JSON.stringify(increments)])
	else:
		res = _core.mock_bridge.increment_player_stats(increments)
	
	var updated_stats: Dictionary = res.get("data", {}) if res.get("success", false) else {}
	if res.get("success", false):
		stats_saved.emit()
	return updated_stats
