extends Control
## Fixed engineering diagram: collision geometry only, 150 px/WU.
## No Camera2D, visual-art radii, camera acceptance or automatic recentering.
const PIXELS_PER_WU := 150.0
var bodies: Array = []


func _draw() -> void:
	var floor_y := size.y - 80.0
	draw_line(Vector2(0.0, floor_y), Vector2(size.x, floor_y), Color.SLATE_GRAY, 2.0)
	for body in bodies:
		var a := Vector2(
			size.x / 2.0 + body.a.x * PIXELS_PER_WU, floor_y - body.a.y * PIXELS_PER_WU
		)
		var b := Vector2(
			size.x / 2.0 + body.b.x * PIXELS_PER_WU, floor_y - body.b.y * PIXELS_PER_WU
		)
		var radius: float = body.radius * PIXELS_PER_WU
		var color := Color.LIGHT_SKY_BLUE
		if body.kind == "head":
			color = Color.GOLD
		elif body.gripping:
			color = Color.LIME_GREEN
		elif body.grounded:
			color = Color.CORAL
		draw_line(a, b, color, radius * 2.0, true)
		draw_circle(a, radius, color)
		draw_circle(b, radius, color)
