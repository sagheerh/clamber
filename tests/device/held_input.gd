extends RefCounted
## Diagnostic input ownership, not a production control implementation.
## A touch never changes channel after assignment; extra touches are ignored.
var _owners: Dictionary = {}


func press(token: String, channel: int, touch: bool = false) -> void:
	if channel not in [1, 2] or _owners.has(token):
		return
	if touch:
		for key in _owners:
			if str(key).begins_with("touch:") and _owners[key] == channel:
				return
	_owners[token] = channel


func release(token: String) -> void:
	_owners.erase(token)


func clear() -> void:
	_owners.clear()


func mask() -> int:
	var value := 0
	for channel in _owners.values():
		value |= int(channel)
	return value
