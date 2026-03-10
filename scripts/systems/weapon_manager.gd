## WeaponManager — manages weapon inventory and switching for a player.
##
## Attach as a child node to the player. Add [BaseWeapon] children representing
## available weapons. Call [method switch_weapon] or [method next_weapon]/[method prev_weapon]
## to change the active weapon.
class_name WeaponManager
extends Node2D

## Emitted when the active weapon changes.
signal weapon_changed(weapon: BaseWeapon)

## Emitted when ammo changes on the active weapon.
signal ammo_changed(current: int, max: int)

## Emitted when a reload starts on the active weapon.
signal reload_started

## Emitted when a reload completes on the active weapon.
signal reload_completed

## The currently active weapon index.
var active_weapon_index: int = 0

var _weapons: Array[BaseWeapon] = []
var _active_weapon: BaseWeapon = null


func _ready() -> void:
	_refresh_weapon_list()
	if _weapons.size() > 0:
		switch_weapon(0)


## Refresh the internal weapon list from child nodes.
func _refresh_weapon_list() -> void:
	_weapons.clear()
	for child in get_children():
		if child is BaseWeapon:
			_weapons.append(child)
			child.visible = false
			# Connect weapon signals
			if not child.ammo_changed.is_connected(_on_weapon_ammo_changed):
				child.ammo_changed.connect(_on_weapon_ammo_changed)
			if not child.reload_started.is_connected(_on_weapon_reload_started):
				child.reload_started.connect(_on_weapon_reload_started)
			if not child.reload_completed.is_connected(_on_weapon_reload_completed):
				child.reload_completed.connect(_on_weapon_reload_completed)


## Switch to the weapon at the given index.
func switch_weapon(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return

	if _active_weapon != null:
		_active_weapon.visible = false

	active_weapon_index = index
	_active_weapon = _weapons[active_weapon_index]
	_active_weapon.visible = true
	weapon_changed.emit(_active_weapon)
	ammo_changed.emit(_active_weapon.current_ammo, _active_weapon.max_ammo)


## Switch to the next weapon in the list (wraps around).
func next_weapon() -> void:
	if _weapons.size() <= 1:
		return
	var next_index := (active_weapon_index + 1) % _weapons.size()
	switch_weapon(next_index)


## Switch to the previous weapon in the list (wraps around).
func prev_weapon() -> void:
	if _weapons.size() <= 1:
		return
	var prev_index := (active_weapon_index - 1 + _weapons.size()) % _weapons.size()
	switch_weapon(prev_index)


## Get the currently active weapon.
func get_active_weapon() -> BaseWeapon:
	return _active_weapon


## Attempt to fire the active weapon.
func try_fire(direction: Vector2, trigger_held: bool) -> bool:
	if _active_weapon == null:
		return false
	return _active_weapon.try_fire(direction, trigger_held)


## Start reloading the active weapon.
func reload() -> void:
	if _active_weapon == null:
		return
	_active_weapon.reload()


## Add a new weapon to the inventory.
func add_weapon(weapon: BaseWeapon) -> void:
	add_child(weapon)
	_refresh_weapon_list()


## Remove a weapon from the inventory by index.
func remove_weapon(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return

	var weapon := _weapons[index]
	if weapon == _active_weapon:
		# Switch to a different weapon if removing active one
		if _weapons.size() > 1:
			next_weapon()
		else:
			_active_weapon = null

	remove_child(weapon)
	weapon.queue_free()
	_refresh_weapon_list()


## Get the total number of weapons in inventory.
func get_weapon_count() -> int:
	return _weapons.size()


func _on_weapon_ammo_changed(current: int, max_ammo: int) -> void:
	if get_active_weapon() == null:
		return
	# Only emit if it's from the active weapon
	ammo_changed.emit(current, max_ammo)


func _on_weapon_reload_started() -> void:
	reload_started.emit()


func _on_weapon_reload_completed() -> void:
	reload_completed.emit()
