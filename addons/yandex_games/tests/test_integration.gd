extends SceneTree

func _init() -> void:
	print("Starting automated integration tests for YandexGames...")
	
	# Wait for autoload
	await process_frame
	
	var yg: Node = root.get_node_or_null("YandexGames")
	if not yg:
		printerr("FAIL: YandexGames autoload not found")
		quit(1)
		return
	
	print("[1/14] Testing init...")
	var ok: bool = yg.init()
	assert(ok == true, "init failed")
	assert(yg.is_initialized == true, "is_initialized should be true")
	
	print("[2/14] Testing Core Lifecycle & Server Time...")
	yg.gameplay_start()
	yg.gameplay_stop()
	var s_time: int = yg.get_server_time()
	assert(s_time > 0, "server time invalid")
	
	print("[3/14] Testing Ads...")
	var inter: Dictionary = await yg.show_interstitial()
	assert(inter.get("success", false) == true, "interstitial failed")
	var rewarded: Dictionary = await yg.show_rewarded()
	assert(rewarded.get("success", false) == true, "rewarded failed")
	assert(rewarded.get("rewarded", false) == true, "reward not granted")
	var banner: Dictionary = await yg.show_banner()
	assert(banner.get("success", false) == true, "show banner failed")
	var hide_banner: Dictionary = await yg.hide_banner()
	assert(hide_banner.get("success", false) == true, "hide banner failed")
	
	print("[4/14] Testing Player & Cloud Saves...")
	assert(yg.player.is_authorized() == true, "player should be authorized in mock")
	assert(not yg.player.get_id().is_empty(), "player id empty")
	assert(not yg.player.get_name().is_empty(), "player name empty")
	
	var saved: bool = await yg.player.set_data({ "test_key": "test_val", "score": 42 }, true)
	assert(saved == true, "set_data failed")
	var data: Dictionary = await yg.player.get_data(["test_key", "score"])
	assert(data.get("test_key") == "test_val", "data mismatch")
	assert(data.get("score") == 42, "score mismatch")
	
	var set_stats_ok: bool = await yg.player.set_stats({ "coins": 100 })
	assert(set_stats_ok == true, "set_stats failed")
	var stats: Dictionary = await yg.player.get_stats(["coins"])
	assert(int(stats.get("coins", 0)) == 100, "stats mismatch")
	var inc_stats: Dictionary = await yg.player.increment_stats({ "coins": 50 })
	assert(int(inc_stats.get("coins", 0)) == 150, "increment stats mismatch")
	
	print("[5/14] Testing Leaderboards...")
	var lb_score_ok: bool = await yg.leaderboards.set_score("test_lb", 500, "hero_warrior")
	assert(lb_score_ok == true, "set_score failed")
	var entry: Dictionary = await yg.leaderboards.get_player_entry("test_lb")
	assert(int(entry.get("score", 0)) == 500, "player entry score mismatch")
	var entries: Dictionary = await yg.leaderboards.get_entries("test_lb", { "quantityTop": 5 })
	assert(entries.has("entries"), "entries key missing")
	
	print("[6/14] Testing Leaderboard Debouncing...")
	yg.leaderboards.set_score_debounced("debounced_lb", 100, "", 0.1)
	yg.leaderboards.set_score_debounced("debounced_lb", 300, "", 0.1)
	yg.leaderboards.set_score_debounced("debounced_lb", 200, "", 0.1)
	await create_timer(0.2).timeout
	var deb_entry: Dictionary = await yg.leaderboards.get_player_entry("debounced_lb")
	assert(int(deb_entry.get("score", 0)) == 300, "debounced score should be 300")
	
	print("[7/14] Testing Payments & Currency...")
	var p_init: bool = await yg.payments.init_payments(true)
	assert(p_init == true, "payments init failed")
	var catalog: Array = await yg.payments.get_catalog()
	assert(catalog.size() > 0, "catalog empty")
	assert(catalog[0].has("currencyImageSvg"), "currencyImageSvg missing from catalog item")
	assert(catalog[0].has("priceCurrencyCode"), "priceCurrencyCode missing from catalog item")
	
	var purchase: Dictionary = await yg.payments.purchase(catalog[0].id)
	assert(purchase.has("purchaseToken"), "purchase token missing")
	assert(purchase.has("signature"), "signature missing in signed purchase")
	var purchases: Array = await yg.payments.get_purchases()
	assert(purchases.size() > 0, "purchases empty after purchase")
	var consumed: bool = await yg.payments.consume_purchase(purchase.purchaseToken)
	assert(consumed == true, "consume purchase failed")
	
	print("[8/14] Testing Environment & Promotions...")
	assert(not yg.environment.get_app_id().is_empty(), "app id empty")
	assert(not yg.environment.get_lang().is_empty(), "lang empty")
	assert(yg.environment.has_promo() == true, "has_promo failed in mock")
	assert(yg.environment.get_promo_id() == "mock_promo_2026", "promo id mismatch")
	assert(yg.environment.get_promo_intent() == "open_shop", "promo intent mismatch")
	assert(yg.environment.get_promo_inapp_id() == "coins_100", "promo inapp mismatch")
	
	print("[9/14] Testing Device & Screen Orientation...")
	assert(not yg.device.get_type().is_empty(), "device type empty")
	var orient: String = yg.device.get_orientation()
	assert(orient in ["portrait", "landscape"], "invalid orientation: " + orient)
	var set_orient: bool = await yg.device.set_orientation("portrait")
	assert(set_orient == true, "set orientation failed")
	
	print("[10/14] Testing Games Cross-Promotion...")
	var all_games: Dictionary = await yg.games.get_all_games()
	assert(all_games.has("developerURL"), "all_games missing developerURL")
	assert(all_games.has("games"), "all_games missing games")
	var games_list: Array = await yg.games.get_games_list()
	assert(games_list is Array, "games_list is not array")
	var game_info: Dictionary = await yg.games.get_game_by_id(12345)
	assert(game_info.has("title"), "game_info missing title")
	
	print("[11/14] Testing Safe Storage & Clipboard...")
	var storage_set: bool = await yg.storage.set_item("mock_store_key", "store_val_123")
	assert(storage_set == true, "storage set failed")
	var storage_get: String = await yg.storage.get_item("mock_store_key")
	assert(storage_get == "store_val_123", "storage get mismatch")
	var clip_ok: bool = await yg.clipboard.write_text("test_clip")
	assert(clip_ok == true, "clipboard write failed")
	
	print("[12/14] Testing Feedback & Shortcuts...")
	var can_rev: Dictionary = await yg.feedback.can_review()
	assert(can_rev.has("value"), "can_review missing value")
	var req_rev: Dictionary = await yg.feedback.request_review()
	assert(req_rev.get("feedback_sent", false) == true, "request_review failed")
	var can_short: bool = await yg.shortcut.can_show_prompt()
	assert(can_short is bool, "can_show_prompt failed")
	var short_prompt: Dictionary = await yg.shortcut.show_prompt()
	assert(short_prompt.has("outcome"), "shortcut outcome missing")
	
	print("[13/14] Testing Remote Config...")
	var flags: Dictionary = await yg.remote_config.get_flags([], { "test_flag": "flag_val" })
	assert(yg.remote_config.get_flag_string("test_flag") == "flag_val", "remote config string mismatch")
	
	print("[14/14] Testing Auto-apply Locale...")
	assert(TranslationServer.get_locale().begins_with("ru"), "locale should be auto-set to ru")
	
	print("\n>>> ALL 14 INTEGRATION TESTS PASSED 100%! <<<")
	quit(0)
