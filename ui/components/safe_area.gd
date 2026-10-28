class_name ClamberSafeArea
extends MarginContainer
## Convert Android physical display coordinates through the root viewport transform.
## Desktop/headless has no display cutout. The navy background remains full bleed.


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


static func content_margins(
	display_rect: Rect2, safe_rect: Rect2, screen_transform: Transform2D
) -> Vector4:
	var inverse := screen_transform.affine_inverse()
	var content := inverse * display_rect
	var safe := inverse * safe_rect.intersection(display_rect)
	return Vector4(
		maxf(0.0, safe.position.x - content.position.x),
		maxf(0.0, safe.position.y - content.position.y),
		maxf(0.0, content.end.x - safe.end.x),
		maxf(0.0, content.end.y - safe.end.y)
	)


func _apply_safe_area() -> void:
	var margins := Vector4.ZERO
	if OS.get_name() == "Android":
		var size := Vector2(DisplayServer.screen_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		if safe.has_area():
			# get_screen_transform includes letterboxing/stretch and window offsets.
			var screen_rect := (
				get_viewport().get_screen_transform() * get_viewport().get_visible_rect()
			)
			margins = content_margins(
				screen_rect.intersection(Rect2(Vector2.ZERO, size)),
				safe,
				get_viewport().get_screen_transform()
			)
	add_theme_constant_override("margin_left", ceili(margins.x))
	add_theme_constant_override("margin_top", ceili(margins.y))
	add_theme_constant_override("margin_right", ceili(margins.z))
	add_theme_constant_override("margin_bottom", ceili(margins.w))
