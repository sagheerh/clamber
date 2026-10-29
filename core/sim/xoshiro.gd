class_name Xoshiro128StarStar
extends RefCounted
## xoshiro128** 1.1 transition; exact unsigned32 arithmetic in signed64 integers.
## Constants below are algorithm bit widths/rotations, NOT physical tuning.
const TUNING = preload("res://core/tuning.tres")
const ONE = TUNING.physics_one
const TWO = TUNING.physics_input_bits_per_tick
const FIVE = TWO + TWO + ONE
const SEVEN = FIVE + TWO
const NINE = SEVEN + TWO
const ELEVEN = NINE + TWO
const WORD_BITS = ONE << FIVE
const WORD_MASK = (ONE << WORD_BITS) - ONE
var _words: Array = []


func configure(run_seed: int) -> void:
	# Explicit bijective seed expansion for int64 seeds; complement prevents all-zero.
	# No generator/jitter consumers are invented; Sim owns this one injected stream.
	var low := run_seed & WORD_MASK
	var high := (run_seed >> WORD_BITS) & WORD_MASK
	_words = [low, high, (~low) & WORD_MASK, (~high) & WORD_MASK]


func next_u32() -> int:
	var output := (_rotate((_words[ONE] * FIVE) & WORD_MASK, SEVEN) * NINE) & WORD_MASK
	var shifted: int = (_words[ONE] << NINE) & WORD_MASK
	_words[TWO] ^= _words[TUNING.physics_zero]
	_words[TWO + ONE] ^= _words[ONE]
	_words[ONE] ^= _words[TWO]
	_words[TUNING.physics_zero] ^= _words[TWO + ONE]
	_words[TWO] ^= shifted
	_words[TWO + ONE] = _rotate(_words[TWO + ONE], ELEVEN)
	return output


func snapshot() -> Array:
	return _words.duplicate()


func restore(words: Array) -> Error:
	if words.size() != TWO * TWO:
		return ERR_INVALID_DATA
	var combined := TUNING.physics_zero
	for word in words:
		if not word is int or word < TUNING.physics_zero or word > WORD_MASK:
			return ERR_INVALID_DATA
		combined |= word
	if combined == TUNING.physics_zero:
		return ERR_INVALID_DATA
	_words = words.duplicate()
	return OK


func _rotate(word: int, count: int) -> int:
	return ((word << count) | (word >> (WORD_BITS - count))) & WORD_MASK
