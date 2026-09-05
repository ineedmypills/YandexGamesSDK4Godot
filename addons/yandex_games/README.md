<p align="center">
  <img src="addons/yandex_games/icon.svg" alt="Yandex Games SDK for Godot" width="128" height="128">
</p>

<h1 align="center">Yandex Games SDK for Godot 4</h1>

<p align="center">
  <b>Universal, Modular, and High-Performance Yandex Games SDK Plugin for Godot Engine</b><br>
  Engineered for Godot 4.3+ with first-class support for <b>GDScript 2.0</b> and <b>C# (.NET 8)</b>
</p>

<p align="center">
  <a href="https://store.godotengine.org/asset/ineedmypills/yandex-games-sdk-for-godot-4/"><img src="https://img.shields.io/badge/Godot%20Asset%20Library-Available-478cbf?logo=godotengine&logoColor=white" alt="Godot Asset Library"></a>
  <a href="https://godotengine.org/"><img src="https://img.shields.io/badge/Godot-4.3+-478cbf?logo=godotengine&logoColor=white" alt="Godot 4.3+"></a>
  <a href="https://dotnet.microsoft.com/"><img src="https://img.shields.io/badge/.NET-8.0-512bd4?logo=dotnet&logoColor=white" alt=".NET 8"></a>
  <a href="https://yandex.ru/dev/games/doc/ru/"><img src="https://img.shields.io/badge/Yandex%20Games-SDK-6b51ff" alt="Yandex Games SDK"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"></a>
</p>

---

## Table of Contents

- [Overview](#overview)
- [Architecture & Dual Runtime](#architecture--dual-runtime)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Lifecycle & Core](#lifecycle--core)
  - [Advertisements](#advertisements)
  - [Player & Authentication](#player--authentication)
  - [Cloud Saves & Numeric Stats](#cloud-saves--numeric-stats)
  - [Leaderboards](#leaderboards)
  - [Payments & In-App Purchases](#payments--in-app-purchases)
  - [Feedback & Reviews](#feedback--reviews)
  - [Desktop & Home Screen Shortcuts](#desktop--home-screen-shortcuts)
  - [Asynchronous Multiplayer Sessions](#asynchronous-multiplayer-sessions)
  - [Remote Configuration & Flags](#remote-configuration--flags)
  - [Device & Screen](#device--screen)
  - [Environment & Locale](#environment--locale)
  - [Cross-Promotion](#cross-promotion)
  - [Platform Events & Smart TV](#platform-events--smart-tv)
  - [Safe Storage & Clipboard](#safe-storage--clipboard)
  - [Audio Management & Pause Handling](#audio-management--pause-handling)
- [C# (.NET) Usage](#c-net-usage)
- [Local Testing & Dev Proxy](#local-testing--dev-proxy)
- [Web Export & Yandex Console Checklist](#web-export--yandex-console-checklist)
- [Editor Mock Mode](#editor-mock-mode)
- [License](#license)

---

## Overview

This plugin provides zero-overhead, plug-and-play integration with the Yandex Games platform for Godot 4.3+.

### Highlights
- **Native Browser Bridge**: Uses Godot 4's `JavaScriptBridge` for direct, high-performance browser communication.
- **Full Offline Mock Mode**: Runs seamlessly in the Godot Editor (F5) on Windows, macOS, and Linux with local disk persistence (`user://yandex_mock_data.json`) and simulated ad delays.
- **Audio Protection**: Automatically mutes the master audio bus during advertisements and browser tab defocus (`game_api_pause` / `game_api_resume`), fulfilling platform moderation requirements.
- **Ready-to-Use Web Template**: Includes an optimized HTML5 export shell with responsive scaling, focus preservation, loading indicator, and disabled context menus.

---

## Architecture & Dual Runtime

The plugin uses a unified API layer that automatically delegates calls based on the runtime environment:

```
+-------------------------------------------------------------------+
|                        Godot Game Project                         |
|           GDScript (YandexGames.*)  /  C# (YandexGames.*)         |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|               YandexGames Coordinator (Autoload)                  |
+-------------------------------------------------------------------+
           |                                             |
     (Web Export)                                 (Editor / Desktop)
           |                                             |
           v                                             v
+-----------------------+                    +----------------------+
|   JavaScriptBridge    |                    |   YandexMockBridge   |
| (yandex_bridge.js)    |                    | (Local disk save in  |
|          |            |                    |  user:// and delays) |
|          v            |                    +----------------------+
|    YaGames SDK        |
+-----------------------+
```

---

## Installation

### Method 1: Godot Asset Library
Install directly from the **[Godot Asset Library](https://store.godotengine.org/asset/ineedmypills/yandex-games-sdk-for-godot-4/)** or via the editor:
1. Open your project in Godot 4.
2. Navigate to the **AssetLib** tab at the top.
3. Search for **Yandex Games SDK** (or view it on the [Godot Asset Store](https://store.godotengine.org/asset/ineedmypills/yandex-games-sdk-for-godot-4/)).
4. Click **Download** and **Install**.
5. Go to **Project -> Project Settings -> Plugins** and enable **Yandex Games SDK**.

### Method 2: Manual Installation
1. Clone or download this repository.
2. Copy the `addons/yandex_games` folder into your project's `addons/` directory.
3. Go to **Project -> Project Settings -> Plugins** and enable **Yandex Games SDK**.
4. The singleton `YandexGames` will be automatically registered in your Autoload settings.

### Project Settings

Configure plugin behavior directly via **Project -> Project Settings -> Yandex Games**:

| Setting | Type | Default | Description |
|---|---|---|---|
| `yandex_games/general/auto_init` | `bool` | `true` | Automatically initializes SDK on startup in Web exports (no boilerplate required). |
| `yandex_games/general/auto_call_game_ready` | `bool` | `true` | Automatically invokes `LoadingAPI.ready()` after initialization. |
| `yandex_games/general/auto_apply_locale` | `bool` | `true` | Sets Godot's `TranslationServer.set_locale()` to Yandex interface language (Rule 2.14). |
| `yandex_games/general/auto_pause_tree` | `bool` | `false` | Automatically pauses `SceneTree` (`get_tree().paused = true`) during platform events and ads. |
| `yandex_games/ads/auto_mute_audio` | `bool` | `true` | Automatically mutes master bus during ads & defocus, safely preserving player's prior sound settings. |
| `yandex_games/ads/interstitial_cooldown` | `float` | `60.0` | Minimum seconds between interstitial ads to comply with platform guidelines. |
| `yandex_games/payments/auto_check_unconsumed`| `bool` | `true` | Automatically checks and restores unconsumed purchases on startup (Rule 1.13.1). |
| `yandex_games/mock/player_name` | `string` | `"Test Player (Editor)"` | Player nickname for editor testing. |
| `yandex_games/mock/player_unique_id` | `string` | `"mock_player_12345"` | Unique player ID for editor testing. |
| `yandex_games/mock/is_authorized` | `bool` | `true` | Authorization state in editor mock mode. |

---

## Quick Start

```gdscript
extends Node

func _ready() -> void:
    # 1. Notify platform that assets are loaded (Required for catalog)
    YandexGames.game_ready()

    # 2. Show an Interstitial Ad
    var ad_result = await YandexGames.show_interstitial()
    if ad_result.was_shown:
        print("Ad completed successfully")

    # 3. Load Cloud Save
    var save_data = await YandexGames.player.get_data()
    print("Player coins:", save_data.get("coins", 0))
```

---

## API Reference

### Lifecycle & Core

The core singleton coordinates platform events and lifecycle states.

```gdscript
# Notify platform that the game is ready (calls LoadingAPI.ready())
YandexGames.game_ready()

# Mark active gameplay start (level start, unpause)
YandexGames.gameplay_start()

# Mark gameplay stop (game over, pause menu)
YandexGames.gameplay_stop()

# Synchronized server timestamp in milliseconds (UTC)
var server_time_ms: int = YandexGames.get_server_time()

# Check if a specific SDK method is supported in the current environment
var has_feature: bool = await YandexGames.is_available_method("leaderboards.setScore")
```

---

### Advertisements

Submodule: `YandexGames.ads` (or top-level shortcuts on `YandexGames`).

#### Methods

```gdscript
# Fullscreen Interstitial Ad
# Returns: { "success": bool, "was_shown": bool, "error": String }
var res: Dictionary = await YandexGames.show_interstitial()

# Check cooldown before showing an ad (configured via ProjectSettings)
if YandexGames.ads.can_show_interstitial():
    await YandexGames.show_interstitial()
else:
    print("%.1fs cooldown remaining" % YandexGames.ads.get_time_until_next_interstitial())

# Or use the convenience shortcut that automatically respects cooldown
var ad_res: Dictionary = await YandexGames.ads.show_interstitial_if_available()

# Rewarded Video Ad
# Returns: { "success": bool, "rewarded": bool, "was_shown": bool, "error": String }
var res: Dictionary = await YandexGames.show_rewarded()
if res.rewarded:
    give_player_reward()

# Sticky Banner
await YandexGames.ads.show_banner()
await YandexGames.ads.hide_banner()
var banner_status = await YandexGames.ads.get_banner_status()
# Returns: { "is_showing": bool, "reason": String }
```

#### Signals

- `YandexGames.ads.interstitial_opened`
- `YandexGames.ads.interstitial_closed(was_shown: bool)`
- `YandexGames.ads.interstitial_failed(error: String)`
- `YandexGames.ads.interstitial_offline`
- `YandexGames.ads.interstitial_cooldown_finished`
- `YandexGames.ads.rewarded_opened`
- `YandexGames.ads.rewarded_rewarded`
- `YandexGames.ads.rewarded_closed(was_shown: bool)`
- `YandexGames.ads.rewarded_failed(error: String)`
- `YandexGames.ads.banner_shown`
- `YandexGames.ads.banner_hidden`
- `YandexGames.ads.banner_status_changed(is_showing: bool, reason: String)`

---

### Player & Authentication

Submodule: `YandexGames.player`.

```gdscript
# Open native Yandex ID login dialog
var info: Dictionary = await YandexGames.player.open_auth_dialog()

# Status and Profile Data
var is_auth: bool = YandexGames.player.is_authorized()
var user_id: String = YandexGames.player.get_id()
var user_name: String = YandexGames.player.get_name()
var avatar_url: String = YandexGames.player.get_photo("medium") # "small", "medium", "large"
var paying_status: String = YandexGames.player.get_paying_status() # "paying" or ""
var signature: String = YandexGames.player.get_signature() # Cryptographic signature for backend validation

# IDs across other games by developer
var cross_ids: Array = await YandexGames.player.get_ids_per_game()

# Load player avatar as Texture2D (with in-memory cache and offline procedural generator)
var avatar_tex: Texture2D = await YandexGames.player.get_avatar_texture("medium")
$AvatarTextureRect.texture = avatar_tex
```

---

### Cloud Saves & Numeric Stats

Submodule: `YandexGames.player`.

```gdscript
# Save data to Cloud (flush = true forces immediate sync)
await YandexGames.player.set_data({
    "coins": 500,
    "level": 3,
    "equipped_skin": "dragon"
}, true)

# Load data from Cloud (pass array of keys or null for all)
var save_data: Dictionary = await YandexGames.player.get_data(["coins", "level"])

# Numeric Statistics
await YandexGames.player.set_stats({ "high_score": 12000 })
var stats: Dictionary = await YandexGames.player.get_stats(["high_score"])

# Atomic cloud increment (safe against race conditions)
var updated_stats = await YandexGames.player.increment_stats({ "enemies_defeated": 10 })
```

---

### Leaderboards

Submodule: `YandexGames.leaderboards`.

```gdscript
# Submit player score (optional extra_data up to 1024 chars)
await YandexGames.leaderboards.set_score("highscores", 2500, "character_mage")

# Debounced score submission (protects against the strict Yandex 1 req/sec rate limit)
# Ideal for runners, clickers, or incremental progress
YandexGames.leaderboards.set_score_debounced("highscores", current_score, "", 1.0)

# Get current player's entry and rank
var player_entry: Dictionary = await YandexGames.leaderboards.get_player_entry("highscores")
print("Rank: ", player_entry.get("rank"), " Score: ", player_entry.get("score"))

# Fetch top entries
var leaderboard: Dictionary = await YandexGames.leaderboards.get_entries("highscores", {
    "quantityTop": 10,
    "includeUser": true,
    "quantityAround": 3
})

for entry in leaderboard.get("entries", []):
    print("#%d %s - %d" % [entry.rank, entry.player.publicName, entry.score])
    # Load entry avatar texture directly:
    var entry_avatar: Texture2D = await YandexGames.leaderboards.load_avatar_texture(entry.player.avatarUrlSmall, entry.player.publicName)

# Get Leaderboard Description
var desc: Dictionary = await YandexGames.leaderboards.get_description("highscores")
```

---

### Payments & In-App Purchases

Submodule: `YandexGames.payments`.

```gdscript
# Initialize payments (optionally pass signed: true for cryptographic purchase verification)
await YandexGames.payments.init_payments(true)

# Automatic unconsumed purchases recovery (Requirement 1.13.1)
# Triggers automatically on startup if yandex_games/payments/auto_check_unconsumed is true
YandexGames.payments.unconsumed_purchases_found.connect(func(unconsumed: Array[Dictionary]) -> void:
    for p in unconsumed:
        print("Restoring unconsumed purchase: ", p.productID)
        grant_reward(p.productID)
    await YandexGames.payments.consume_all_purchases()
)

# Fetch Product Catalog with automatic currency icon detection (Requirement 1.13.2)
var catalog: Array = await YandexGames.payments.get_catalog()
for item in catalog:
    print(item.id, ": ", item.title, " - ", YandexGames.payments.get_price_formatted(item))
    print("Currency Code: ", item.priceCurrencyCode)
    print("Currency Icon URL: ", item.currencyImageSvg) # or item.currencyImageSmall / currencyImageMedium

# Purchase Item
# If signed mode is active, purchase dictionary will contain a "signature" field
var purchase: Dictionary = await YandexGames.payments.purchase("coins_pack_100", "payload_123")
if not purchase.is_empty():
    give_purchased_item()
    
    # Consume consumable item (mandatory before game close for consumable products)
    var token = purchase.get("purchaseToken", "")
    await YandexGames.payments.consume_purchase(token)

# Retrieve active purchases (unconsumed or permanent)
var purchases: Array = await YandexGames.payments.get_purchases()
```

---

### Feedback & Reviews

Submodule: `YandexGames.feedback`.

```gdscript
# Check eligibility
var status: Dictionary = await YandexGames.feedback.can_review()
if status.get("value", false):
    # Open review dialog
    var result: Dictionary = await YandexGames.feedback.request_review()
    print("Feedback sent: ", result.get("feedback_sent", false))
else:
    print("Cannot review: ", status.get("reason", "UNKNOWN"))
```

---

### Desktop & Home Screen Shortcuts

Submodule: `YandexGames.shortcut`.

```gdscript
# Check availability
if await YandexGames.shortcut.can_show_prompt():
    var res = await YandexGames.shortcut.show_prompt()
    print("Prompt outcome: ", res.get("outcome")) # "accepted" or "rejected"
```

---

### Asynchronous Multiplayer Sessions

Submodule: `YandexGames.multiplayer_sessions`.

Record player timeline transactions and play against ghost opponents without maintaining custom backend servers.

```gdscript
# 1. Initialize sessions and fetch opponents
var opponents: Array[Dictionary] = await YandexGames.multiplayer_sessions.init_sessions({
    "count": 2,
    "isEventBased": true,
    "maxOpponentTurnTime": 3000,
    "meta": {
        "meta1": { "min": 0, "max": 5000 }
    }
})

# 2. Commit player actions during gameplay
YandexGames.multiplayer_sessions.commit({ "action": "jump", "x": 12.4, "y": 4.0 })

# 3. Publish session on match finish
await YandexGames.multiplayer_sessions.push({ "meta1": final_score })

# Signals for event-based playback:
YandexGames.multiplayer_sessions.transaction_received.connect(func(opponent_id: String, transactions: Array[Dictionary]) -> void:
    apply_opponent_actions(opponent_id, transactions)
)
YandexGames.multiplayer_sessions.session_finished.connect(func(opponent_id: String) -> void:
    on_opponent_finish(opponent_id)
)
```

---

### Remote Configuration & Flags

Submodule: `YandexGames.remote_config`.

```gdscript
# Fetch flags with optional client features and default fallbacks
var flags: Dictionary = await YandexGames.remote_config.get_flags(
    [{ "name": "cohort", "value": "beta" }],
    { "difficulty": "normal", "promo_active": "false", "starting_coins": "100" }
)

var difficulty: String = YandexGames.remote_config.get_flag_string("difficulty", "normal")
var promo_on: bool = YandexGames.remote_config.get_flag_bool("promo_active", false)
var coins: int = YandexGames.remote_config.get_flag_int("starting_coins", 100)
```

---

### Device & Screen

Submodule: `YandexGames.device`.

```gdscript
# Device Type
var device_type: String = YandexGames.device.get_type() # "desktop", "mobile", "tablet", "tv"
var is_mob: bool = YandexGames.device.is_mobile()
var is_tv: bool = YandexGames.device.is_tv()

# Browser Fullscreen
var is_fs: bool = YandexGames.device.is_fullscreen()
await YandexGames.device.request_fullscreen()
await YandexGames.device.exit_fullscreen()

# Screen Orientation (portrait / landscape)
var orientation: String = YandexGames.device.get_orientation()
await YandexGames.device.set_orientation("portrait")
```

---

### Environment & Locale

Submodule: `YandexGames.environment`.

```gdscript
var app_id: String = YandexGames.environment.get_app_id()
var lang: String = YandexGames.environment.get_lang() # "ru", "en", "tr", etc.
var browser_lang: String = YandexGames.environment.get_browser_lang()
var tld: String = YandexGames.environment.get_tld() # "ru", "com", "by", "kz", etc.
var payload: String = YandexGames.environment.get_payload() # URL query parameters

# Automatic Language Detection (Requirement 2.14)
# Enabled by default via auto_apply_locale: sets Godot TranslationServer.set_locale(lang) on startup!

# Promotions & Deeplinks (ysdk.environment.referrer)
if YandexGames.environment.has_promo():
    var promo_id: String = YandexGames.environment.get_promo_id()
    var intent: String = YandexGames.environment.get_promo_intent() # e.g. "open_shop", "open_starter_pack"
    var inapp_id: String = YandexGames.environment.get_promo_inapp_id() # in-app item ID for discount
    if not inapp_id.is_empty():
        open_discount_purchase_dialog(inapp_id)
    elif not intent.is_empty():
        navigate_to_screen(intent)
```

---

### Cross-Promotion

Submodule: `YandexGames.games`.

```gdscript
# Fetch all games published by developer with developer URL
# Returns: { "developerURL": String, "games": Array[Dictionary] }
var catalog_info: Dictionary = await YandexGames.games.get_all_games()
print("Developer page: ", catalog_info.get("developerURL"))

# Convenience helper to get just the list of games
var games_list: Array[Dictionary] = await YandexGames.games.get_games_list()

# Get details of a specific game (accepts int or string ID)
var game_info: Dictionary = await YandexGames.games.get_game_by_id(123456)
```

---

### Platform Events & Smart TV

Handle platform-specific navigation events, hardware Back buttons, and Smart TV exit confirmation.

```gdscript
# Connect to hardware/browser Back button request (essential for mobile & Smart TV navigation)
YandexGames.history_back_requested.connect(func() -> void:
    if is_in_sub_menu():
        close_sub_menu()
    else:
        show_quit_dialog()
)

# When the user confirms exit from the game (mandatory requirement for Smart TV moderation):
YandexGames.dispatch_exit()

# Or dispatch custom SDK events:
YandexGames.dispatch_event("EXIT")

# Track account selection dialog status:
YandexGames.account_selection_opened.connect(func() -> void:
    print("Account selection dialog appeared")
)
YandexGames.account_selection_closed.connect(func() -> void:
    print("Account selection dialog closed")
)
```

---

### Safe Storage & Clipboard

```gdscript
# Safe LocalStorage (handles Safari Private Browsing quota restrictions)
await YandexGames.storage.set_item("user_settings", "{ \"sound\": true }")
var settings_json: String = await YandexGames.storage.get_item("user_settings")

# System Clipboard
await YandexGames.clipboard.write_text("https://yandex.ru/games/app/...")
```

---

### Audio Management & Pause Handling

The plugin automatically listens to `game_api_pause` and `game_api_resume` platform events (triggered on tab switch, window minimize, or system dialogs).

- `auto_mute_audio = true` (Default): Automatically mutes `AudioServer` master bus on pause and ad display, then safely restores the bus volume without overriding the player's intentional in-game sound settings.
- `auto_pause_tree = true` (Optional, configured in ProjectSettings): Automatically sets `get_tree().paused = true` during platform pause and ads.
- Signals:
  - `YandexGames.game_paused`
  - `YandexGames.game_resumed`

---

### Ready-to-Use UI Components

The plugin provides plug-and-play Godot UI nodes located in `addons/yandex_games/ui/`:

#### 1. `YandexBannerContainer` (`MarginContainer`)
Drop-in container that automatically listens to `banner_shown` and `banner_hidden` signals and animates its margins so that gameplay buttons and HUD elements are never obstructed by sticky banners (ensures full compliance with Yandex Requirement 1.6.1.4).
- `banner_position`: `BOTTOM` or `TOP`
- `banner_height_pixels`: Offset in pixels (default `70`)
- `animate`: Smoothly animates margin transition using a Tween
- `editor_preview_banner`: Toggle directly in the Godot inspector to preview banner padding in the 2D canvas editor!

#### 2. `YandexReviewButton` (`Button`)
Self-managing review button for the Yandex Games rating dialog:
- Automatically calls `can_review()` on `_ready()`.
- Hides itself if the player has already rated the game or if the platform does not support reviews.
- On click, prompts `request_review()`, emits `review_completed(feedback_sent)`, and automatically hides if the review was sent.

#### 3. `YandexShortcutButton` (`Button`)
Self-managing button for adding desktop or home screen shortcuts:
- Automatically calls `can_show_prompt()` on `_ready()`.
- Hides itself on desktop browsers or when the shortcut is already installed.
- On click, prompts `show_prompt()`, emits `shortcut_prompt_completed(outcome)`, and hides when accepted.

---

## C# (.NET) Usage

All functions are available as type-safe asynchronous tasks (`Task<T>`) under the `YandexGamesSDK` namespace:

```csharp
using Godot;
using System.Threading.Tasks;
using YandexGamesSDK;

public partial class GameManager : Node
{
    public override async void _Ready()
    {
        // 1. Ready Notification
        YandexGames.GameReady();

        // 2. Interstitial Ad
        var adResult = await YandexGames.Ads.ShowInterstitialAsync();

        // 3. Rewarded Ad
        var rewardResult = await YandexGames.Ads.ShowRewardedAsync();
        if (rewardResult.ContainsKey("rewarded") && (bool)rewardResult["rewarded"])
        {
            GD.Print("Reward granted!");
        }

        // 4. Cloud Save
        var data = new Godot.Collections.Dictionary { { "level", 10 } };
        await YandexGames.Player.SetDataAsync(data, true);

        // 5. Leaderboards
        await YandexGames.Leaderboards.SetScoreAsync("highscores", 5000);
    }
}
```

---

## Local Testing & Dev Proxy

Testing Yandex Games locally during development is officially supported via multiple workflows. You do **not** have to upload a `.zip` archive to the Yandex Console for every minor change.

### Option 1: `@yandex-games/sdk-dev-proxy` (Recommended)

Yandex provides an official proxy tool (`@yandex-games/sdk-dev-proxy`) that serves local files with the appropriate headers, CSP, and mock SDK or platform proxying.

#### Dev Mode (No Console Draft Needed)
In dev mode, the proxy serves your exported game directory using a local mock SDK and supports local testing of purchases, ads, and player profiles without needing a real Yandex account or draft:

```bash
# Serve your exported Web directory in dev mode
npx @yandex-games/sdk-dev-proxy -p ./build/web --dev-mode=true
```

Open `http://localhost:8080/` in your browser.
- **Mock purchases**: The plugin automatically creates `purchases-catalog.json` in your web export directory. The proxy serves this file under `http://localhost:8080/purchases-catalog.json`.
- **Query overrides**: You can customize mock behavior by passing URL params, e.g. `http://localhost:8080/?mocks={"payments":true}`.

#### Prod Mode (Proxying into Real Platform)
Test your local code directly inside the live Yandex Games iframe environment:

```bash
# Proxy local folder into real application draft
npx @yandex-games/sdk-dev-proxy -p ./build/web --app-id=<YOUR_APP_ID>

# Or proxy an existing local dev server (e.g. Godot web export server)
npx @yandex-games/sdk-dev-proxy -h http://localhost:8060 --app-id=<YOUR_APP_ID>
```

### Option 2: Manual Local Server Setup (`game_url`)

You can test a draft game directly from any local HTTP server (such as Godot's built-in one-click web server or Python's `python -m http.server 8060`) inside the Yandex Games iframe:

1. In the Yandex Developer Console, ensure your application has a draft saved.
2. Start your local server serving your exported web files (e.g., `http://localhost:8060`).
3. Open the following URL in your browser:
   ```
   https://yandex.ru/games/app/<YOUR_APP_ID>?draft=true&game_url=http://localhost:8060&debug-mode=16
   ```

> [!NOTE]
> **Strict Platform Compliance**: In accordance with Yandex Games moderation requirements, the SDK script is loaded exclusively via `<script src="/sdk.js"></script>` without direct links to S3 service storage (`s3.yandex.net`). For local browser testing outside of Yandex, use the built-in Dev Proxy (`npx @yandex-games/sdk-dev-proxy`) or Editor Mock Mode.

### Option 3: Editor Quick Tools

In the Godot editor, navigate to **Project → Tools**:
- **Yandex Games: Auto-Configure Web Preset**: Automatically configures existing or new Web export presets with the Yandex HTML shell in 1 click.
- **Yandex Games: Package Web Export to Yandex ZIP**: Packages exported web files from `res://build/web` into a compliant ZIP archive with `index.html` at the archive root.
- **Yandex Games: Reset Mock Data**: Clears `user://yandex_mock_data.json` for clean editor retesting.
- **Yandex Games: Copy Dev Proxy Command (Dev Mode)**: Copies the ready-to-run `npx @yandex-games/sdk-dev-proxy ...` dev-mode command to your clipboard.
- **Yandex Games: Copy Dev Proxy Command (Prod Mode)**: Copies the prod-mode command with your configured App ID.
- **Yandex Games: Copy Manual Local Server Draft URL**: Copies the `https://yandex.ru/games/app/...` testing URL to your clipboard.
- **Yandex Games: Create purchases-catalog.json**: Creates/refreshes the catalog JSON in your project root or export folder.
- **Yandex Games: Open Documentation & Console**: Quick browser launcher to official documentation.

### Monitoring the Loading Indicator in Developer Console

When running in `debug-mode=16` or testing in the developer console, look at the Yandex debug panel in the upper corner:
- **`IT`** (Init Time): Time taken to initialize the SDK.
- **`IF`** (First Frame): Time taken to render the first frame.
- **`W`** (Wait / Loading): Time elapsed until `YandexGames.game_ready()` was triggered. Ensure this is called promptly once your assets and title screen are loaded so the platform knows your game is ready.

---

## Web Export & Yandex Console Checklist

### 1. Godot Export Preset

When you enable the plugin, a **"Web (Yandex Games)"** export preset is created automatically in `export_presets.cfg` — including the correct **Custom HTML Shell** pointing to `yandex_template.html`. Nothing to configure manually.

**If you already had a Web preset before installing this plugin**, open **Project → Export**, select your preset, and set **Options → Custom HTML Shell** to:
```
res://addons/yandex_games/templates/yandex_template.html
```
The export window will show a warning banner until this is set correctly.

Once the preset is ready:
1. Set **Export Type** to `Regular` (or `Threads` if your project requires multithreading).
2. Click **Export Project** and save the `.zip` archive.

### 2. Yandex Developer Console Requirements
- [x] **SDK Connection**: Relative `<script src="/sdk.js">` used with automated CDN fallback.
- [x] **Context Menu & Selection**: Disabled on canvas (`user-select: none`, `oncontextmenu="event.preventDefault();"`) (Requirements 1.6.1.8, 1.6.2.7).
- [x] **Game Ready**: Called once assets are ready (`YandexGames.game_ready()`) within 90s (Requirement 1.19.2).
- [x] **Automatic Language Detection**: Auto-detection via `i18n.lang` applied to Godot's `TranslationServer` at launch (Requirement 2.14).
- [x] **Portal Currency Detection**: Automatically formatted with `priceCurrencyCode` and `currencyImageSvg` (Requirement 1.13.2).
- [x] **Gameplay Markup**: Active gameplay intervals marked via `gameplay_start()` / `gameplay_stop()` (Requirement 1.19.3).
- [x] **Rate Limit Protection**: 1 req/sec limit on leaderboards respected via `set_score_debounced()`.
- [x] **Audio & Focus Protection**: Mutes audio on tab switch and ad display (Requirements 1.3, 4.7, 1.19.4).
- [x] **Smart TV & Back Button**: Supported via `history_back_requested` and `dispatch_exit()` (Requirement 1.6.3).
- [x] **Purchase Consumption**: In-app purchases correctly consumed via `payments.consume_purchase()` (Requirement 1.13.1).

---

## Editor Mock Mode

When testing within the Godot Editor (F5) or running desktop builds, the plugin switches to `YandexMockBridge`:

- **Disk Persistence**: Player saves, stats, and purchases persist across runs in `user://yandex_mock_data.json`.
- **Simulated Delays**: Ad watching and network queries emulate realistic network latency.
- **Interactive Testing**: Open `addons/yandex_games/examples/demo.tscn` to test every feature via a ready-made UI dashboard.

---

## License

This project is licensed under the [MIT License](LICENSE).
