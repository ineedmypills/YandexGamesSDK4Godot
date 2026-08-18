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

        private static Node? Instance
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

        public static void GameReady() => Instance?.Call("game_ready");
        public static void GameplayStart() => Instance?.Call("gameplay_start");
        public static void GameplayStop() => Instance?.Call("gameplay_stop");
        public static long GetServerTime() => Instance != null ? (long)Instance.Call("get_server_time") : DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        public static class Ads
        {
            private static GodotObject? Module => Instance?.Get("ads").As<GodotObject>();

            public static async Task<Dictionary> ShowInterstitialAsync()
            {
                if (Module == null) return new Dictionary();
                var task = Module.Call("show_interstitial");
                var tree = Engine.GetMainLoop() as SceneTree;
                if (tree != null)
                {
                    await tree.ToSignal(Module, "interstitial_closed");
                }
                return task.As<Dictionary>() ?? new Dictionary();
            }

            public static async Task<Dictionary> ShowRewardedAsync()
            {
                if (Module == null) return new Dictionary();
                var task = Module.Call("show_rewarded");
                var tree = Engine.GetMainLoop() as SceneTree;
                if (tree != null)
                {
                    await tree.ToSignal(Module, "rewarded_closed");
                }
                return task.As<Dictionary>() ?? new Dictionary();
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
            public static string GetPhoto(string size = "medium") => Module != null ? Module.Call("get_photo", size).AsString() : "";

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
        }

        public static class Leaderboards
        {
            private static GodotObject? Module => Instance?.Get("leaderboards").As<GodotObject>();

            public static async Task<bool> SetScoreAsync(string name, int score, string extraData = "")
            {
                if (Module == null) return false;
                var res = Module.Call("set_score", name, score, extraData);
                return res.AsBool();
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
        }

        public static class Payments
        {
            private static GodotObject? Module => Instance?.Get("payments").As<GodotObject>();

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
            private static GodotObject? Module => Instance?.Get("multiplayer").As<GodotObject>();

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
