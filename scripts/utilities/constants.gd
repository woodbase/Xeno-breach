## GameConstants — static constants shared across the entire project.
##
## Physics layer values match the Godot collision layer assignments in project.godot.
## Import via [code]GameConstants.LAYER_PLAYER[/code] etc.
class_name GameConstants
extends RefCounted

# --- Physics Layers (bitmask values) ---

## CharacterBody2D player entity.
const LAYER_PLAYER: int = 1

## CharacterBody2D enemy entities.
const LAYER_ENEMIES: int = 2

## StaticBody2D world geometry.
const LAYER_WORLD: int = 4

## Area2D player projectiles.
const LAYER_PLAYER_PROJECTILES: int = 8

## Area2D enemy projectiles.
const LAYER_ENEMY_PROJECTILES: int = 16

# --- Collision Masks ---

## Player projectile hits enemies and world.
const MASK_PLAYER_PROJECTILE: int = LAYER_ENEMIES | LAYER_WORLD

## Enemy projectile hits player and world.
const MASK_ENEMY_PROJECTILE: int = LAYER_PLAYER | LAYER_WORLD

# --- Scene Paths ---

const SCENE_TEST_LEVEL: String = "res://scenes/levels/test_level.tscn"
const SCENE_PLAYER: String = "res://scenes/player/player.tscn"
const SCENE_ENEMY_BASE: String = "res://scenes/enemies/enemy_base.tscn"
const SCENE_PROJECTILE: String = "res://scenes/weapons/projectile.tscn"
const SCENE_ENEMY_PROJECTILE: String = "res://scenes/weapons/enemy_projectile.tscn"
const SCENE_HUD: String = "res://scenes/ui/hud.tscn"
