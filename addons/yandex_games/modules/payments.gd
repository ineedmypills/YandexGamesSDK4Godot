@tool
class_name YandexPayments
extends RefCounted

## Manages In-App Purchases, Product Catalog, and Purchase Consumption.

signal purchase_success(purchase: Dictionary)
signal purchase_failed(error: String)
signal catalog_loaded(catalog: Array)
signal purchases_loaded(purchases: Array)

var _core = null

func _init(core) -> void:
	_core = core

## Initializes the Payments subsystem (optional signed parameter).
func init(options: Dictionary = {}) -> bool:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("initPayments", [JSON.stringify(options)])
	else:
		res = { "success": true }
	return res.get("success", false)

## Purchases an in-game product by ID.
## Returns Dictionary with purchase data or empty on failure.
func purchase(product_id: String, developer_payload: String = "") -> Dictionary:
	var res: Dictionary
	var options = {
		"id": product_id,
		"developerPayload": developer_payload
	}
	
	if _core.is_web():
		res = await _core.call_js_async("purchase", [JSON.stringify(options)])
	else:
		res = _core.mock_bridge.purchase(options)
	
	if res.get("success", false):
		var purchase_data = res.get("data", {})
		purchase_success.emit(purchase_data)
		return purchase_data
	else:
		var err = res.get("error", "Purchase failed")
		purchase_failed.emit(err)
		return {}

## Retrieves the in-game products catalog configured in Yandex Console.
func get_catalog() -> Array:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getCatalog")
	else:
		res = _core.mock_bridge.get_catalog()
	
	var catalog = res.get("data", []) if res.get("success", false) else []
	catalog_loaded.emit(catalog)
	return catalog

## Retrieves a list of all active (unconsumed / permanent) purchases.
func get_purchases() -> Array:
	var res: Dictionary
	if _core.is_web():
		res = await _core.call_js_async("getPurchases")
	else:
		res = _core.mock_bridge.get_purchases()
	
	var purchases = res.get("data", []) if res.get("success", false) else []
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
