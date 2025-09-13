extends Node
class_name UnitUtils

static var TILE_SIZE: int = 32

static func tiles_to_px(tiles: float) -> float:
	return tiles * TILE_SIZE

static func px_to_tiles(px: float) -> float:
	return px / TILE_SIZE
