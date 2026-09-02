extends Sprite2D

# Slow living backdrop for a still pixel-art image.
#
# The texture is deliberately larger than the 480x360 viewport so it can drift
# without ever exposing an edge. Keep drift_x below the horizontal margin and
# drift_y below the vertical one:
#   margin_x = (texture_width  - 480) / 2
#   margin_y = (texture_height - 360) / 2
#
# Movement is snapped to whole pixels. Sub-pixel motion under the project's
# nearest-neighbour filter makes pixel art crawl and shimmer.

@export var drift_x := 10.0				# pixels either side of centre
@export var drift_y := 8.0
@export var period_x := 23.0			# seconds for a full sweep
@export var period_y := 17.0			# deliberately not a multiple of period_x
@export var glow_amount := 0.06			# brightness swing, 0 disables
@export var glow_period := 11.0

var _origin: Vector2
var _tint: Color
var _t := 0.0


func _ready():
	centered = true
	_origin = position
	_tint = modulate
	_apply()


func _process(delta):
	_t += delta
	_apply()


func _apply():
	position = Vector2(
		_origin.x + round(sin(TAU * _t / period_x) * drift_x),
		_origin.y + round(cos(TAU * _t / period_y) * drift_y)
	)
	if glow_amount > 0.0:
		# oscillate between (1 - glow_amount) and 1, never brighter than the art
		var k: float = 1.0 - glow_amount * (0.5 + 0.5 * sin(TAU * _t / glow_period))
		modulate = Color(_tint.r * k, _tint.g * k, _tint.b * k, _tint.a)
