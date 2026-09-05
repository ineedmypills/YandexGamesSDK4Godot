@tool
class_name YandexPayments
extends RefCounted

## Manages In-App Purchases, Product Catalog, and Purchase Consumption.

signal purchase_success(purchase: Dictionary)
signal purchase_failed(error: String)
signal catalog_loaded(catalog: Array[Dictionary])
signal purchases_loaded(purchases: Array[Dictionary])
signal unconsumed_purchases_found(purchases: Array[Dictionary])

var _core: Node = null
var auto_check_unconsumed: bool = true

func _init(core: Node) -> void:
	_core = core
	auto_check_unconsumed = bool(ProjectSettings.get_setting("yandex_games/payments/auto_check_unconsumed", true))

## Initializes the Payments subsystem.
## Set options = { "signed": true } for server-side fraud protection signature validation.
func init(options: Dictionary = {}) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("initPayments", [JSON.stringify(options)])
	else:
		if _core.mock_bridge:
			_core.mock_bridge.is_signed = bool(options.get("signed", _core.mock_bridge.is_signed))
		res = { "success": true }
	
	var ok: bool = res.get("success", false)
	if ok and auto_check_unconsumed:
		check_unconsumed_purchases()
	return ok

## Convenience method to initialize payments with signed fraud protection flag.
func init_payments(signed: bool = false) -> bool:
	return await init({ "signed": signed })

## Purchases an in-game product by ID.
## Returns Dictionary with purchase data or empty on failure.
func purchase(product_id: String, developer_payload: String = "") -> Dictionary:
	var res: Dictionary
	var options: Dictionary = {
		"id": product_id,
		"developerPayload": developer_payload
	}
	
	if _core.is_web():
		res = await _core.call_js_async("purchase", [JSON.stringify(options)], 300.0)
	else:
		res = _core.mock_bridge.purchase(options)
	
	if res.get("success", false):
		var purchase_data: Dictionary = res.get("data", {})
		purchase_success.emit(purchase_data)
		return purchase_data
	else:
		var err: String = str(res.get("error", "Purchase failed"))
		purchase_failed.emit(err)
		return {}

## Retrieves the in-game products catalog configured in Yandex Console.
func get_catalog() -> Array[Dictionary]:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getCatalog")
		var catalog: Array[Dictionary] = []
		if res.get("success", false):
			for item: Dictionary in res.get("data", []):
				catalog.append(item)
		catalog_loaded.emit(catalog)
		return catalog
	else:
		var catalog: Array[Dictionary] = _core.mock_bridge.get_catalog()
		catalog_loaded.emit(catalog)
		return catalog

## Retrieves a list of all active (unconsumed / permanent) purchases.
func get_purchases() -> Array[Dictionary]:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getPurchases")
		var purchases: Array[Dictionary] = []
		if res.get("success", false):
			for item: Dictionary in res.get("data", []):
				purchases.append(item)
		purchases_loaded.emit(purchases)
		return purchases
	else:
		var purchases: Array[Dictionary] = _core.mock_bridge.get_purchases()
		purchases_loaded.emit(purchases)
		return purchases

## Consumes a consumable in-app purchase using its purchaseToken.
func consume_purchase(purchase_token: String) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("consumePurchase", [purchase_token])
	else:
		res = _core.mock_bridge.consume_purchase(purchase_token)
	return res.get("success", false)

## Checks for any unconsumed purchases from previous interrupted sessions (Requirement 1.13.1).
func check_unconsumed_purchases() -> Array[Dictionary]:
	var purchases: Array[Dictionary] = await get_purchases()
	if not purchases.is_empty():
		unconsumed_purchases_found.emit(purchases)
	return purchases

## Consumes all currently active unconsumed purchases.
## Useful for auto-restoring or consuming all pending items at startup.
func consume_all_purchases() -> Array[Dictionary]:
	var purchases: Array[Dictionary] = await get_purchases()
	var consumed_list: Array[Dictionary] = []
	for p in purchases:
		var token: String = str(p.get("purchaseToken", ""))
		if not token.is_empty():
			var ok: bool = await consume_purchase(token)
			if ok:
				consumed_list.append(p)
	return consumed_list

## Returns a nicely formatted price string (e.g. "50 YAN" or "99 ₽").
func get_price_formatted(product: Dictionary) -> String:
	var price_str: String = str(product.get("price", ""))
	if not price_str.is_empty():
		return price_str
	var val: String = str(product.get("priceValue", ""))
	var cur: String = str(product.get("priceCurrencyCode", ""))
	if not cur.is_empty():
		return "%s %s" % [val, cur]
	return val
