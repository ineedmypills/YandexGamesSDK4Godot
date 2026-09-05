extends SceneTree

var _pass_count: int = 0
var _fail_count: int = 0

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] %s" % test_name)
	else:
		_fail_count += 1
		printerr("[FAIL] %s" % test_name)

func _init() -> void:
	process_frame.connect(_run_tests, CONNECT_ONE_SHOT)

func _run_tests() -> void:
	print("\n==========================================")
	print("  Yandex Games SDK 4 Godot - Test Suite")
	print("==========================================\n")
	
	# Instantiate YandexGames node manually
	var yg_script: GDScript = load("res://addons/yandex_games/yandex_games.gd") as GDScript
	var yg: Node = yg_script.new()
	root.add_child(yg)
	
	# 1. Initialization
	var init_ok: bool = yg.init()
	_assert(init_ok, "Core: init() returns true")
	_assert(yg.is_initialized, "Core: is_initialized == true")
	
	# 2. Lifecycle
	yg.game_ready()
	yg.gameplay_start()
	yg.gameplay_stop()
	var server_time: int = yg.get_server_time()
	_assert(server_time > 0, "Core: get_server_time() > 0")
	var is_avail: bool = yg.is_available_method("feedback.canReview")
	_assert(is_avail, "Core: is_available_method() == true")
	
	# 3. Environment
	_assert(yg.environment.get_app_id() != "", "Environment: get_app_id() is not empty")
	_assert(yg.environment.get_lang() == "ru", "Environment: get_lang() == 'ru'")
	_assert(yg.environment.get_tld() == "ru", "Environment: get_tld() == 'ru'")
	_assert(yg.environment.get_browser_lang() == "ru", "Environment: get_browser_lang() == 'ru'")
	_assert(yg.environment.get_all() is Dictionary, "Environment: get_all() is Dictionary")
	_assert(typeof(yg.environment.has_promo()) == TYPE_BOOL, "Environment: has_promo() is bool")
	_assert(yg.environment.get_referrer() is Dictionary, "Environment: get_referrer() is Dictionary")
	
	# 4. Device
	_assert(yg.device.get_type() in ["desktop", "mobile", "tablet", "tv"], "Device: get_type() is valid")
	_assert(typeof(yg.device.is_mobile()) == TYPE_BOOL, "Device: is_mobile() is bool")
	_assert(typeof(yg.device.is_desktop()) == TYPE_BOOL, "Device: is_desktop() is bool")
	_assert(typeof(yg.device.is_fullscreen()) == TYPE_BOOL, "Device: is_fullscreen() is bool")
	_assert(yg.device.request_fullscreen(), "Device: request_fullscreen() == true")
	_assert(yg.device.exit_fullscreen(), "Device: exit_fullscreen() == true")
	_assert(yg.device.get_orientation() != "", "Device: get_orientation() is non-empty")
	_assert(yg.device.set_orientation("portrait"), "Device: set_orientation() returns true")
	
	# 5. Player & Auth
	_assert(yg.player.is_authorized(), "Player: is_authorized() in mock mode == true")
	_assert(yg.player.get_id() != "", "Player: get_id() is not empty")
	_assert(yg.player.get_name() != "", "Player: get_name() is not empty")
	_assert(yg.player.get_photo("small") != "", "Player: get_photo('small') is not empty")
	var ids_per_game: Array[Dictionary] = yg.player.get_ids_per_game()
	_assert(ids_per_game.size() > 0, "Player: get_ids_per_game() has entries")
	
	# 6. Cloud Saves & Stats
	var save_res: bool = yg.player.set_data({ "test_coins": 500, "test_hero": "Knight" }, true)
	_assert(save_res, "Player: set_data() returns true")
	var load_data: Dictionary = yg.player.get_data(["test_coins", "test_hero"])
	_assert(load_data.get("test_coins") == 500, "Player: get_data() coins == 500")
	_assert(load_data.get("test_hero") == "Knight", "Player: get_data() hero == 'Knight'")
	
	var set_stats_res: bool = yg.player.set_stats({ "kills": 10 })
	_assert(set_stats_res, "Player: set_stats() returns true")
	var inc_stats_res: Dictionary = yg.player.increment_stats({ "kills": 5 })
	_assert(inc_stats_res.get("kills") == 15, "Player: increment_stats() kills == 15")
	var get_stats_res: Dictionary = yg.player.get_stats(["kills"])
	_assert(get_stats_res.get("kills") == 15, "Player: get_stats() kills == 15")
	
	# 7. Ads
	var banner_res: Dictionary = yg.show_banner()
	_assert(banner_res.get("success", false) == true, "Ads: show_banner() success")
	var banner_status: Dictionary = yg.ads.get_banner_status()
	_assert(banner_status.get("is_showing", false) == true, "Ads: get_banner_status() is_showing")
	var banner_hide_res: Dictionary = yg.hide_banner()
	_assert(banner_hide_res.get("success", false) == true, "Ads: hide_banner() success")
	
	var ad_interstitial: Dictionary = await yg.show_interstitial()
	_assert(ad_interstitial.get("success", false) == true, "Ads: show_interstitial() success")
	
	var ad_rewarded: Dictionary = await yg.show_rewarded()
	_assert(ad_rewarded.get("success", false) == true, "Ads: show_rewarded() success")
	_assert(ad_rewarded.get("rewarded", false) == true, "Ads: show_rewarded() rewarded")
	
	# 8. Leaderboards
	var desc: Dictionary = yg.leaderboards.get_description("test_lb")
	_assert(desc.get("name") == "test_lb", "Leaderboards: get_description() name matches")
	var set_score_ok: bool = yg.leaderboards.set_score("test_lb", 9999, "extra_info")
	_assert(set_score_ok, "Leaderboards: set_score() returns true")
	yg.leaderboards.set_score_debounced("test_lb", 12000, "extra_info")
	var player_entry: Dictionary = yg.leaderboards.get_player_entry("test_lb")
	_assert(player_entry.get("score") == 9999, "Leaderboards: get_player_entry() score == 9999")
	var entries: Dictionary = yg.leaderboards.get_entries("test_lb", { "quantityTop": 5 })
	_assert(entries.get("entries", []).size() > 0, "Leaderboards: get_entries() has entries")
	_assert(typeof(yg.is_platform_paused) == TYPE_BOOL, "Core: is_platform_paused is bool")
	
	# 9. Payments
	var catalog: Array[Dictionary] = yg.payments.get_catalog()
	_assert(catalog.size() > 0, "Payments: get_catalog() has products")
	var purchase_res: Dictionary = yg.payments.purchase("coins_100", "payload_123")
	_assert(purchase_res.get("productID") == "coins_100", "Payments: purchase() productID matches")
	var token: String = purchase_res.get("purchaseToken", "")
	_assert(token != "", "Payments: purchase() returned token")
	var purchases: Array[Dictionary] = yg.payments.get_purchases()
	_assert(purchases.size() > 0, "Payments: get_purchases() has active purchases")
	var consume_ok: bool = yg.payments.consume_purchase(token)
	_assert(consume_ok, "Payments: consume_purchase() returns true")
	
	# 10. Feedback
	var can_rev: Dictionary = yg.feedback.can_review()
	_assert(can_rev.has("value"), "Feedback: can_review() has 'value'")
	var rev_res: Dictionary = await yg.feedback.request_review()
	_assert(rev_res.get("value", false) == true, "Feedback: request_review() returns value == true")
	
	# 11. Shortcut
	var can_sc: bool = yg.shortcut.can_show_prompt()
	_assert(typeof(can_sc) == TYPE_BOOL, "Shortcut: can_show_prompt() is bool")
	var sc_res: Dictionary = await yg.shortcut.show_prompt()
	_assert(sc_res.get("outcome") == "accepted", "Shortcut: show_prompt() outcome == 'accepted'")
	
	# 12. Storage
	var set_stor: bool = yg.storage.set_item("pref_key", "pref_value_123")
	_assert(set_stor, "Storage: set_item() returns true")
	var get_stor: String = yg.storage.get_item("pref_key")
	_assert(get_stor == "pref_value_123", "Storage: get_item() == 'pref_value_123'")
	
	# 13. Remote Config
	var flags: Dictionary = yg.remote_config.get_flags([], { "theme": "dark", "difficulty": 2, "audio_on": true })
	_assert(flags.get("theme") == "dark", "RemoteConfig: default flag theme == 'dark'")
	_assert(yg.remote_config.get_flag_string("theme") == "dark", "RemoteConfig: get_flag_string('theme') == 'dark'")
	_assert(yg.remote_config.get_flag_int("difficulty") == 2, "RemoteConfig: get_flag_int('difficulty') == 2")
	_assert(yg.remote_config.get_flag_bool("audio_on") == true, "RemoteConfig: get_flag_bool('audio_on') == true")
	
	# 14. Games
	var all_games: Dictionary = yg.games.get_all_games()
	_assert(all_games.has("developerURL"), "Games: get_all_games() has developerURL")
	var games_list: Array[Dictionary] = yg.games.get_games_list()
	_assert(games_list.size() > 0, "Games: get_games_list() has entries")
	var game_info: Dictionary = yg.games.get_game_by_id("mock_game_1")
	_assert(game_info.get("appID") == "mock_game_1", "Games: get_game_by_id() appID matches")
	
	# 15. Clipboard
	var clip_ok: bool = yg.clipboard.write_text("Hello Yandex Games")
	_assert(clip_ok, "Clipboard: write_text() returns true")
	
	# 16. Multiplayer Sessions
	var sessions: Array[Dictionary] = yg.multiplayer_sessions.init_sessions({ "count": 2 })
	_assert(sessions.size() == 2, "Multiplayer: init_sessions({ count: 2 }) returns 2 sessions")
	yg.multiplayer_sessions.commit({ "action": "jump", "x": 10.0 })
	var push_ok: bool = yg.multiplayer_sessions.push({ "score": 100 })
	_assert(push_ok, "Multiplayer: push() returns true")
	
	# 17. Ad Cooldown & Banner State
	_assert(yg.ads.can_show_interstitial() == false, "Ads: can_show_interstitial() is false right after ad")
	_assert(yg.ads.get_time_until_next_interstitial() > 0.0, "Ads: get_time_until_next_interstitial() > 0")
	var blocked_ad: Dictionary = yg.ads.show_interstitial_if_available()
	_assert(blocked_ad.get("success", true) == false, "Ads: show_interstitial_if_available() blocked by cooldown")
	_assert(yg.ads.is_banner_showing == false, "Ads: is_banner_showing is false after hide")

	# 18. Avatar Texture Loader & Offline Generator
	var p_avatar: Texture2D = await yg.player.get_avatar_texture("medium")
	_assert(p_avatar != null and p_avatar.get_width() > 0, "Player: get_avatar_texture() returned valid texture")
	var lb_avatar: Texture2D = await yg.leaderboards.load_avatar_texture("https://mock-avatar.net/test.png", "Alex")
	_assert(lb_avatar != null and lb_avatar.get_height() > 0, "Leaderboards: load_avatar_texture() returned valid texture")

	# 19. Payments Unconsumed Purchases & Price Formatter
	var unconsumed: Array[Dictionary] = await yg.payments.check_unconsumed_purchases()
	_assert(unconsumed is Array, "Payments: check_unconsumed_purchases() returns Array")
	var formatted_price: String = yg.payments.get_price_formatted({ "price": "150 YAN" })
	_assert(formatted_price == "150 YAN", "Payments: get_price_formatted() matches")

	# 20. UI Helper Nodes
	var banner_container: YandexBannerContainer = YandexBannerContainer.new()
	root.add_child(banner_container)
	banner_container.editor_preview_banner = true
	_assert(banner_container.get_theme_constant("margin_bottom") == banner_container.banner_height_pixels, "UI: YandexBannerContainer offsets margin")
	banner_container.queue_free()

	var rev_btn: YandexReviewButton = YandexReviewButton.new()
	root.add_child(rev_btn)
	var can_rev_btn: bool = await rev_btn.check_eligibility()
	_assert(typeof(can_rev_btn) == TYPE_BOOL, "UI: YandexReviewButton check_eligibility returns bool")
	rev_btn.queue_free()

	var sc_btn: YandexShortcutButton = YandexShortcutButton.new()
	root.add_child(sc_btn)
	var can_sc_btn: bool = await sc_btn.check_eligibility()
	_assert(typeof(can_sc_btn) == TYPE_BOOL, "UI: YandexShortcutButton check_eligibility returns bool")
	sc_btn.queue_free()

	# 21. Export Preset Configuration Tool
	var preset_res: Dictionary = YandexGamesExportPlugin.configure_web_presets("res://export_presets.cfg")
	_assert(preset_res.get("success", false) == true, "Export: configure_web_presets() success")
	
	print("\n==========================================")
	print("  TEST RESULTS: PASS: %d, FAIL: %d" % [_pass_count, _fail_count])
	print("==========================================\n")
	
	if _fail_count == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<")
		quit(1)
