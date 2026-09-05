#if GODOT_REAL_T_IS_DOUBLE || true
using System;
using System.Threading.Tasks;
using Godot;
using Godot.Collections;

namespace YandexGamesSDK
{
    /// <summary>
    /// Type-safe C# bindings for the Yandex Games SDK 4.x Godot addon.
    /// </summary>
    public static class YandexGames
    {
        private static Node? _instance;

        public static Node? Instance
        {
            get
            {
                if (_instance == null || !GodotObject.IsInstanceValid(_instance))
                {
                    var tree = Engine.GetMainLoop() as SceneTree;
                    _instance = tree?.Root?.GetNodeOrNull("YandexGames");
                }
                return _instance;
            }
        }

        public static bool IsAvailable => Instance != null;
        public static bool IsInitialized => Instance != null && Instance.Get("is_initialized").AsBool();
        public static bool IsWeb => Instance != null && Instance.Call("is_web").AsBool();
        public static bool IsPlatformPaused => Instance != null && Instance.Get("is_platform_paused").AsBool();

        public static async Task<bool> InitAsync(Dictionary? options = null)
        {
            if (Instance == null) return false;
            var res = Instance.Call("init", options ?? new Dictionary());
            return res.AsBool();
        }

        public static async Task<bool> InitAsync(bool signed)
        {
            return await InitAsync(new Dictionary { { "signed", signed } });
        }

        public static async Task<bool> EnsureInitializedAsync()
        {
            if (Instance == null) return false;
            var res = Instance.Call("ensure_initialized");
            return res.AsBool();
        }

        public static void GameReady() => Instance?.Call("game_ready");
        public static void GameplayStart() => Instance?.Call("gameplay_start");
        public static void GameplayStop() => Instance?.Call("gameplay_stop");
        public static long GetServerTime() => Instance != null ? (long)Instance.Call("get_server_time") : DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        public static async Task<bool> IsAvailableMethodAsync(string methodName)
        {
            if (Instance == null) return false;
            var res = Instance.Call("is_available_method", methodName);
            return res.AsBool();
        }

        public static void OnHistoryBack(Action callback) => Instance?.Connect("history_back_requested", Callable.From(callback));
        public static void OnAccountSelectionOpened(Action callback) => Instance?.Connect("account_selection_opened", Callable.From(callback));
        public static void OnAccountSelectionClosed(Action callback) => Instance?.Connect("account_selection_closed", Callable.From(callback));
        public static void OnGamePaused(Action callback) => Instance?.Connect("game_paused", Callable.From(callback));
        public static void OnGameResumed(Action callback) => Instance?.Connect("game_resumed", Callable.From(callback));
        public static void OnSdkInitialized(Action<Dictionary> callback) => Instance?.Connect("sdk_initialized", Callable.From(callback));

        public static class Events
        {
            public static void DispatchExit() => Instance?.Call("dispatch_exit");

            public static async Task<bool> DispatchEventAsync(string eventName, Dictionary? detail = null)
            {
                if (Instance == null) return false;
                var res = Instance.Call("dispatch_event", eventName, detail ?? new Dictionary());
                return res.AsBool();
            }
        }

        public static class Ads
        {
            private static GodotObject? Module => Instance?.Get("ads").As<GodotObject>();

            public static async Task<Dictionary> ShowInterstitialAsync()
            {
                if (Module == null) return new Dictionary();
                var tcs = new TaskCompletionSource<Dictionary>();

                Callable onClosed = default;
                Callable onFailed = default;
                Callable onOffline = default;

                void Cleanup()
                {
                    if (Module != null && GodotObject.IsInstanceValid(Module))
                    {
                        if (Module.IsConnected("interstitial_closed", onClosed))
                            Module.Disconnect("interstitial_closed", onClosed);
                        if (Module.IsConnected("interstitial_failed", onFailed))
                            Module.Disconnect("interstitial_failed", onFailed);
                        if (Module.IsConnected("interstitial_offline", onOffline))
                            Module.Disconnect("interstitial_offline", onOffline);
                    }
                }

                onClosed = Callable.From((bool wasShown) =>
                {
                    Cleanup();
                    tcs.TrySetResult(new Dictionary
                    {
                        { "success", true },
                        { "was_shown", wasShown },
                        { "error", "" }
                    });
                });

                onFailed = Callable.From((string error) =>
                {
                    Cleanup();
                    tcs.TrySetResult(new Dictionary
                    {
                        { "success", false },
                        { "was_shown", false },
                        { "error", error }
                    });
                });

                onOffline = Callable.From(() =>
                {
                    Cleanup();
                    tcs.TrySetResult(new Dictionary
                    {
                        { "success", false },
                        { "was_shown", false },
                        { "error", "Offline" }
                    });
                });

                Module.Connect("interstitial_closed", onClosed, (uint)GodotObject.ConnectFlags.OneShot);
                Module.Connect("interstitial_failed", onFailed, (uint)GodotObject.ConnectFlags.OneShot);
                Module.Connect("interstitial_offline", onOffline, (uint)GodotObject.ConnectFlags.OneShot);

                Module.Call("show_interstitial");
                return await tcs.Task;
            }

            public static async Task<Dictionary> ShowRewardedAsync()
            {
                if (Module == null) return new Dictionary();
                var tcs = new TaskCompletionSource<Dictionary>();
                bool gotReward = false;

                Callable onRewarded = default;
                Callable onClosed = default;
                Callable onFailed = default;

                void Cleanup()
                {
                    if (Module != null && GodotObject.IsInstanceValid(Module))
                    {
                        if (Module.IsConnected("rewarded_rewarded", onRewarded))
                            Module.Disconnect("rewarded_rewarded", onRewarded);
                        if (Module.IsConnected("rewarded_closed", onClosed))
                            Module.Disconnect("rewarded_closed", onClosed);
                        if (Module.IsConnected("rewarded_failed", onFailed))
                            Module.Disconnect("rewarded_failed", onFailed);
                    }
                }

                onRewarded = Callable.From(() =>
                {
                    gotReward = true;
                });

                onClosed = Callable.From((bool wasShown) =>
                {
                    Cleanup();
                    tcs.TrySetResult(new Dictionary
                    {
                        { "success", true },
                        { "rewarded", gotReward },
                        { "was_shown", wasShown },
                        { "error", "" }
                    });
                });

                onFailed = Callable.From((string error) =>
                {
                    Cleanup();
                    tcs.TrySetResult(new Dictionary
                    {
                        { "success", false },
                        { "rewarded", false },
                        { "was_shown", false },
                        { "error", error }
                    });
                });

                Module.Connect("rewarded_rewarded", onRewarded, (uint)GodotObject.ConnectFlags.OneShot);
                Module.Connect("rewarded_closed", onClosed, (uint)GodotObject.ConnectFlags.OneShot);
                Module.Connect("rewarded_failed", onFailed, (uint)GodotObject.ConnectFlags.OneShot);

                Module.Call("show_rewarded");
                return await tcs.Task;
            }

            public static bool IsBannerShowing => Module != null && Module.Get("is_banner_showing").AsBool();
            public static int BannerHeightPixels => Module != null ? Module.Get("banner_height_pixels").AsInt32() : 70;

            public static bool CanShowInterstitial() => Module != null && Module.Call("can_show_interstitial").AsBool();
            public static float GetTimeUntilNextInterstitial() => Module != null ? (float)Module.Call("get_time_until_next_interstitial") : 0f;

            public static void OnInterstitialCooldownFinished(Action callback) => Module?.Connect("interstitial_cooldown_finished", Callable.From(callback));

            public static async Task<Dictionary> ShowInterstitialIfAvailableAsync(bool ignoreCooldown = false)
            {
                if (!ignoreCooldown && !CanShowInterstitial())
                {
                    return new Dictionary
                    {
                        { "success", false },
                        { "was_shown", false },
                        { "error", $"Interstitial cooldown active ({GetTimeUntilNextInterstitial():F1}s remaining)" }
                    };
                }
                return await ShowInterstitialAsync();
            }

            public static async Task<Dictionary> ShowBannerAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("show_banner");
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> HideBannerAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("hide_banner");
                return res.As<Dictionary>() ?? new Dictionary();
            }
        }

        public static class Player
        {
            private static GodotObject? Module => Instance?.Get("player").As<GodotObject>();

            public static bool IsAuthorized => Module != null && Module.Call("is_authorized").AsBool();
            public static string UniqueId => Module != null ? Module.Call("get_id").AsString() : "";
            public static string Name => Module != null ? Module.Call("get_name").AsString() : "";
            public static string Signature => Module != null ? Module.Call("get_signature").AsString() : "";
            public static string PayingStatus => Module != null ? Module.Call("get_paying_status").AsString() : "";
            public static bool IsPaying => PayingStatus == "paying" || PayingStatus == "partially_paying";
            public static string GetPhoto(string size = "medium") => Module != null ? Module.Call("get_photo", size).AsString() : "";

            public static async Task<Dictionary> InitAsync(Dictionary? options = null)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("init", options ?? new Dictionary());
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> InitAsync(bool signed)
            {
                return await InitAsync(new Dictionary { { "signed", signed } });
            }

            public static async Task<Dictionary> OpenAuthDialogAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("open_auth_dialog");
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> GetDataAsync(Array<string>? keys = null)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_data", keys ?? new Variant());
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<bool> SetDataAsync(Dictionary data, bool flush = false)
            {
                if (Module == null) return false;
                var res = Module.Call("set_data", data, flush);
                return res.AsBool();
            }

            public static async Task<Dictionary> GetStatsAsync(Array<string>? keys = null)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_stats", keys ?? new Variant());
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<bool> SetStatsAsync(Dictionary stats)
            {
                if (Module == null) return false;
                var res = Module.Call("set_stats", stats);
                return res.AsBool();
            }

            public static async Task<Dictionary> IncrementStatsAsync(Dictionary increments)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("increment_stats", increments);
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Texture2D?> GetAvatarTextureAsync(string size = "medium")
            {
                if (Module == null) return null;
                var res = Module.Call("get_avatar_texture", size);
                return res.As<Texture2D>();
            }

            public static async Task<Texture2D?> LoadTextureFromUrlAsync(string url, string fallbackText = "P")
            {
                if (Module == null) return null;
                var res = Module.Call("load_texture_from_url", url, fallbackText);
                return res.As<Texture2D>();
            }
        }

        public static class Leaderboards
        {
            private static GodotObject? Module => Instance?.Get("leaderboards").As<GodotObject>();

            public static async Task<Dictionary> GetDescriptionAsync(string name)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_description", name);
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<bool> SetScoreAsync(string name, int score, string extraData = "")
            {
                if (Module == null) return false;
                var res = Module.Call("set_score", name, score, extraData);
                return res.AsBool();
            }

            public static void SetScoreDebounced(string name, int score, string extraData = "", float delaySec = 1.0f)
            {
                Module?.Call("set_score_debounced", name, score, extraData, delaySec);
            }

            public static async Task<Dictionary> GetPlayerEntryAsync(string name)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_player_entry", name);
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> GetEntriesAsync(string name, Dictionary? options = null)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_entries", name, options ?? new Dictionary());
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Texture2D?> LoadAvatarTextureAsync(string url, string fallbackName = "Player")
            {
                if (Module == null) return null;
                var res = Module.Call("load_avatar_texture", url, fallbackName);
                return res.As<Texture2D>();
            }
        }

        public static class Payments
        {
            private static GodotObject? Module => Instance?.Get("payments").As<GodotObject>();

            public static async Task<bool> InitAsync(bool signed = false)
            {
                if (Module == null) return false;
                var res = Module.Call("init_payments", signed);
                return res.AsBool();
            }

            public static async Task<Dictionary> PurchaseAsync(string productId, string developerPayload = "")
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("purchase", productId, developerPayload);
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Array<Dictionary>> GetCatalogAsync()
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("get_catalog");
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static async Task<Array<Dictionary>> GetPurchasesAsync()
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("get_purchases");
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static async Task<bool> ConsumePurchaseAsync(string purchaseToken)
            {
                if (Module == null) return false;
                var res = Module.Call("consume_purchase", purchaseToken);
                return res.AsBool();
            }

            public static async Task<Array<Dictionary>> CheckUnconsumedPurchasesAsync()
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("check_unconsumed_purchases");
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static async Task<Array<Dictionary>> ConsumeAllPurchasesAsync()
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("consume_all_purchases");
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static string GetPriceFormatted(Dictionary product)
            {
                return Module != null ? Module.Call("get_price_formatted", product).AsString() : "";
            }

            public static void OnUnconsumedPurchasesFound(Action<Array<Dictionary>> callback) => Module?.Connect("unconsumed_purchases_found", Callable.From(callback));
        }

        public static class Games
        {
            private static GodotObject? Module => Instance?.Get("games").As<GodotObject>();

            public static async Task<Dictionary> GetAllGamesAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_all_games");
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Array<Dictionary>> GetGamesListAsync()
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("get_games_list");
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static async Task<Dictionary> GetGameByIdAsync(Variant appId)
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("get_game_by_id", appId);
                return res.As<Dictionary>() ?? new Dictionary();
            }
        }

        public static class Device
        {
            private static GodotObject? Module => Instance?.Get("device").As<GodotObject>();

            public static string Type => Module != null ? Module.Call("get_type").AsString() : "desktop";
            public static bool IsMobile => Module != null && Module.Call("is_mobile").AsBool();
            public static bool IsTablet => Module != null && Module.Call("is_tablet").AsBool();
            public static bool IsDesktop => Module == null || Module.Call("is_desktop").AsBool();
            public static bool IsTv => Module != null && Module.Call("is_tv").AsBool();
            public static bool IsFullscreen => Module != null && Module.Call("is_fullscreen").AsBool();
            public static string Orientation => Module != null ? Module.Call("get_orientation").AsString() : "landscape";

            public static async Task<bool> RequestFullscreenAsync()
            {
                if (Module == null) return false;
                var res = Module.Call("request_fullscreen");
                return res.AsBool();
            }

            public static async Task<bool> ExitFullscreenAsync()
            {
                if (Module == null) return false;
                var res = Module.Call("exit_fullscreen");
                return res.AsBool();
            }

            public static async Task<bool> SetOrientationAsync(string orientation)
            {
                if (Module == null) return false;
                var res = Module.Call("set_orientation", orientation);
                return res.AsBool();
            }
        }

        public static class Environment
        {
            private static GodotObject? Module => Instance?.Get("environment").As<GodotObject>();

            public static string AppId => Module != null ? Module.Call("get_app_id").AsString() : "";
            public static string BrowserLang => Module != null ? Module.Call("get_browser_lang").AsString() : "ru";
            public static string Lang => Module != null ? Module.Call("get_lang").AsString() : "ru";
            public static string Tld => Module != null ? Module.Call("get_tld").AsString() : "ru";
            public static string Payload => Module != null ? Module.Call("get_payload").AsString() : "";
            public static Dictionary Referrer => Module != null ? Module.Call("get_referrer").As<Dictionary>() : new Dictionary();
            public static bool HasPromo => Module != null && Module.Call("has_promo").AsBool();
            public static string PromoId => Module != null ? Module.Call("get_promo_id").AsString() : "";
            public static string PromoIntent => Module != null ? Module.Call("get_promo_intent").AsString() : "";
            public static string PromoInappId => Module != null ? Module.Call("get_promo_inapp_id").AsString() : "";
            public static Dictionary GetAll() => Module != null ? Module.Call("get_all").As<Dictionary>() : new Dictionary();
        }

        public static class RemoteConfig
        {
            private static GodotObject? Module => Instance?.Get("remote_config").As<GodotObject>();

            public static async Task<Dictionary> GetFlagsAsync(Godot.Collections.Array? clientFeatures = null, Dictionary? defaultFlags = null)
            {
                if (Module == null) return defaultFlags ?? new Dictionary();
                var res = Module.Call("get_flags", clientFeatures ?? new Godot.Collections.Array(), defaultFlags ?? new Dictionary());
                return res.As<Dictionary>() ?? (defaultFlags ?? new Dictionary());
            }

            public static string GetString(string key, string defaultValue = "") =>
                Module != null ? Module.Call("get_flag_string", key, defaultValue).AsString() : defaultValue;

            public static bool GetBool(string key, bool defaultValue = false) =>
                Module != null ? Module.Call("get_flag_bool", key, defaultValue).AsBool() : defaultValue;

            public static int GetInt(string key, int defaultValue = 0) =>
                Module != null ? Module.Call("get_flag_int", key, defaultValue).AsInt32() : defaultValue;
        }

        public static class Storage
        {
            private static GodotObject? Module => Instance?.Get("storage").As<GodotObject>();

            public static async Task<string> GetItemAsync(string key, string defaultValue = "")
            {
                if (Module == null) return defaultValue;
                var res = Module.Call("get_item", key, defaultValue);
                return res.AsString();
            }

            public static async Task<bool> SetItemAsync(string key, string value)
            {
                if (Module == null) return false;
                var res = Module.Call("set_item", key, value);
                return res.AsBool();
            }
        }

        public static class Clipboard
        {
            private static GodotObject? Module => Instance?.Get("clipboard").As<GodotObject>();

            public static async Task<bool> WriteTextAsync(string text)
            {
                if (Module == null) return false;
                var res = Module.Call("write_text", text);
                return res.AsBool();
            }
        }

        public static class Feedback
        {
            private static GodotObject? Module => Instance?.Get("feedback").As<GodotObject>();

            public static async Task<Dictionary> CanReviewAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("can_review");
                return res.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> RequestReviewAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("request_review");
                return res.As<Dictionary>() ?? new Dictionary();
            }
        }

        public static class Shortcut
        {
            private static GodotObject? Module => Instance?.Get("shortcut").As<GodotObject>();

            public static async Task<bool> CanShowPromptAsync()
            {
                if (Module == null) return false;
                var res = Module.Call("can_show_prompt");
                return res.AsBool();
            }

            public static async Task<Dictionary> ShowPromptAsync()
            {
                if (Module == null) return new Dictionary();
                var res = Module.Call("show_prompt");
                return res.As<Dictionary>() ?? new Dictionary();
            }
        }

        public static class Multiplayer
        {
            private static GodotObject? Module => Instance?.Get("multiplayer_sessions").As<GodotObject>();

            public static async Task<Array<Dictionary>> InitSessionsAsync(Dictionary options)
            {
                if (Module == null) return new Array<Dictionary>();
                var res = Module.Call("init_sessions", options);
                return res.As<Array<Dictionary>>() ?? new Array<Dictionary>();
            }

            public static void Commit(Dictionary payload)
            {
                Module?.Call("commit", payload);
            }

            public static async Task<bool> PushAsync(Dictionary meta)
            {
                if (Module == null) return false;
                var res = Module.Call("push", meta);
                return res.AsBool();
            }
        }
    }
}
#endif
