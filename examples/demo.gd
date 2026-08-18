extends Control

@onready var log_label: RichTextLabel = $VBoxContainer/LogPanel/RichTextLabel
@onready var player_info_label: Label = $VBoxContainer/TopBar/PlayerInfoLabel

var _coins: int = 0
var _level: int = 1

func _ready() -> void:
	_log("[color=yellow]=== Yandex Games SDK Demo Started ===[/color]")
	
	# Connect signals
	YandexGames.ads.interstitial_closed.connect(func(was_shown): _log("Interstitial Closed (Shown: %s)" % str(was_shown)))
	YandexGames.ads.rewarded_rewarded.connect(func(): 
		_coins += 50
		_log("[color=green]+50 Coins rewarded! Total coins: %d[/color]" % _coins)
		_update_ui()
	)
	YandexGames.player.authorized.connect(func(info):
		_log("[color=green]Player Authorized:[/color] %s" % str(info.get("name", "Unknown")))
		_update_ui()
	)
	
	_update_ui()

func _log(text: String) -> void:
	if log_label:
		log_label.append_text(text + "\n")
	print(text)

func _update_ui() -> void:
	var name_str = YandexGames.player.get_name()
	if name_str.is_empty():
		name_str = "Guest / Unauthorized"
	player_info_label.text = "Player: %s | Coins: %d | Level: %d" % [name_str, _coins, _level]

# --- Ads Section ---

func _on_btn_interstitial_pressed() -> void:
	_log("Requesting Interstitial Ad...")
	var res = await YandexGames.show_interstitial()
	_log("Interstitial result: %s" % str(res))

func _on_btn_rewarded_pressed() -> void:
	_log("Requesting Rewarded Video Ad...")
	var res = await YandexGames.show_rewarded()
	_log("Rewarded result: %s" % str(res))

func _on_btn_banner_show_pressed() -> void:
	_log("Showing Sticky Banner...")
	var res = await YandexGames.show_banner()
	_log("Banner show result: %s" % str(res))

func _on_btn_banner_hide_pressed() -> void:
	_log("Hiding Sticky Banner...")
	var res = await YandexGames.hide_banner()
	_log("Banner hide result: %s" % str(res))

# --- Player & Saves Section ---

func _on_btn_auth_dialog_pressed() -> void:
	_log("Opening Auth Dialog...")
	var info = await YandexGames.player.open_auth_dialog()
	_log("Auth dialog result: %s" % str(info))
	_update_ui()

func _on_btn_save_cloud_pressed() -> void:
	_log("Saving game state to Cloud...")
	var data = {
		"coins": _coins,
		"level": _level,
		"saved_at": Time.get_datetime_string_from_system()
	}
	var success = await YandexGames.player.set_data(data, true)
	_log("Save cloud result: %s" % ("OK" if success else "Failed"))

func _on_btn_load_cloud_pressed() -> void:
	_log("Loading game state from Cloud...")
	var data = await YandexGames.player.get_data()
	_log("Loaded cloud data: %s" % str(data))
	if data.has("coins"):
		_coins = int(data.coins)
	if data.has("level"):
		_level = int(data.level)
	_update_ui()

func _on_btn_inc_stats_pressed() -> void:
	_level += 1
	_log("Incrementing stats in Cloud...")
	var res = await YandexGames.player.increment_stats({ "level": 1, "played_sessions": 1 })
	_log("Increment stats result: %s" % str(res))
	_update_ui()

# --- Leaderboard Section ---

func _on_btn_set_score_pressed() -> void:
	var score = _coins * 10 + _level * 100
	_log("Submitting score %d to leaderboard 'main_leaderboard'..." % score)
	var ok = await YandexGames.leaderboards.set_score("main_leaderboard", score)
	_log("Score submitted: %s" % ("OK" if ok else "Failed"))

func _on_btn_get_leaderboard_pressed() -> void:
	_log("Fetching leaderboard 'main_leaderboard' entries...")
	var entries = await YandexGames.leaderboards.get_entries("main_leaderboard", { "quantityTop": 5 })
	_log("Leaderboard data: %s" % str(entries))

# --- In-App Purchases Section ---

func _on_btn_get_catalog_pressed() -> void:
	_log("Fetching Payments Catalog...")
	var catalog = await YandexGames.payments.get_catalog()
	_log("Catalog products (%d): %s" % [catalog.size(), str(catalog)])

func _on_btn_purchase_pressed() -> void:
	_log("Attempting purchase 'coins_100'...")
	var purchase = await YandexGames.payments.purchase("coins_100")
	_log("Purchase result: %s" % str(purchase))
	if not purchase.is_empty():
		_coins += 100
		_update_ui()
		# Auto consume
		var token = purchase.get("purchaseToken", "")
		if not token.is_empty():
			await YandexGames.payments.consume_purchase(token)
			_log("Consumed purchase token: %s" % token)

# --- Feedback & Shortcut Section ---

func _on_btn_review_pressed() -> void:
	_log("Checking canReview...")
	var can_rev = await YandexGames.feedback.can_review()
	_log("Can review: %s" % str(can_rev))
	if can_rev.get("value", false):
		var res = await YandexGames.feedback.request_review()
		_log("Review request result: %s" % str(res))

func _on_btn_shortcut_pressed() -> void:
	_log("Checking canShowPrompt for Shortcut...")
	var can_show = await YandexGames.shortcut.can_show_prompt()
	_log("Can show shortcut: %s" % str(can_show))
	if can_show:
		var res = await YandexGames.shortcut.show_prompt()
		_log("Shortcut prompt outcome: %s" % str(res))

# --- Environment & Misc ---

func _on_btn_env_info_pressed() -> void:
	_log("App ID: %s" % YandexGames.environment.get_app_id())
	_log("Language: %s (Browser: %s, TLD: %s)" % [
		YandexGames.environment.get_lang(),
		YandexGames.environment.get_browser_lang(),
		YandexGames.environment.get_tld()
	])
	_log("Device: %s (Mobile: %s, TV: %s)" % [
		YandexGames.device.get_type(),
		str(YandexGames.device.is_mobile()),
		str(YandexGames.device.is_tv())
	])
	_log("Server Time: %d" % YandexGames.get_server_time())

func _on_btn_clear_log_pressed() -> void:
	if log_label:
		log_label.clear()
