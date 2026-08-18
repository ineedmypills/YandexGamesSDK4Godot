@tool
class_name YandexPayments
extends RefCounted

## Manages In-App Purchases, Product Catalog, and Purchase Consumption.

signal purchase_success(purchase: Dictionary)
signal purchase_failed(error: String)
signal catalog_loaded(catalog: Array[Dictionary])
signal purchases_loaded(purchases: Array[Dictionary])

var _core: Node = null

func _init(core: Node) -> void:
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
	var options: Dictionary = {
		"id": product_id,
		"developerPayload": developer_payload
	}
	
	if _core.is_web():
		res = await _core.call_js_async("purchase", [JSON.stringify(options)])
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
