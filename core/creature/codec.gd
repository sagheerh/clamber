# gdlint: disable=unused-argument
class_name CreatureCodec
extends RefCounted
## M0 interface only. Codec belongs to M4; no payload format invented here.


static func encode(c: CreatureModel) -> String:
	return ""


static func decode(s: String) -> DecodeResult:
	return null
