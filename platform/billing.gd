class_name BillingService
extends RefCounted
## No products or entitlement grants. TODO(Android): pinned billing adapter after M3.
signal purchase_completed(product_id: String, success: bool)
signal restore_completed(success: bool)


func is_available() -> bool:
	return false


func purchase(product_id: String) -> void:
	purchase_completed.emit(product_id, false)


func restore_purchases() -> void:
	restore_completed.emit(false)
