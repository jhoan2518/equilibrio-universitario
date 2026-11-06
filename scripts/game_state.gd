extends Node

signal resources_changed
signal exhausted

var energy: float = 100.0
var study: float = 50.0
var rest: float = 70.0
var social: float = 70.0
var week: int = 1
var boss_active: bool = false
var is_concentrated: bool:
	get:
		return study > 50.0 and rest > 50.0 and social > 50.0

var _exhaustion_sent := false

func reset() -> void:
	energy = 100.0
	study = 50.0
	rest = 70.0
	social = 70.0
	week = 1
	boss_active = false
	_exhaustion_sent = false
	resources_changed.emit()

func tick(delta: float, room: String, fighting: bool) -> void:
	if room != "Biblioteca / Salón":
		study = maxf(0.0, study - 0.35 * delta)
	if room == "Tu cuarto":
		rest = minf(100.0, rest + 5.0 * delta)
	elif room == "Cafetería / Parque":
		social = minf(100.0, social + 5.0 * delta)
	if fighting:
		rest = maxf(0.0, rest - 0.55 * delta)
		social = maxf(0.0, social - 0.30 * delta)
	_check_exhaustion()
	resources_changed.emit()

func al_derrotar_enemigo(points: float = 8.0) -> void:
	study = clampf(study + points, 0.0, 100.0)
	rest = clampf(rest - 2.0, 0.0, 100.0)
	social = clampf(social - 1.5, 0.0, 100.0)
	resources_changed.emit()

func al_atacar() -> void:
	rest = maxf(0.0, rest - 0.18)
	social = maxf(0.0, social - 0.08)
	resources_changed.emit()

func recibir_golpe(amount: float = 10.0) -> void:
	energy = maxf(0.0, energy - amount)
	_check_exhaustion()
	resources_changed.emit()

func recuperar(tipo: String, amount: float) -> void:
	match tipo:
		"energia":
			energy = clampf(energy + amount, 0.0, 100.0)
		"descanso":
			rest = clampf(rest + amount, 0.0, 100.0)
		"social":
			social = clampf(social + amount, 0.0, 100.0)
	resources_changed.emit()

func _check_exhaustion() -> void:
	if not _exhaustion_sent and (energy <= 0.0 or study <= 0.0 or rest <= 0.0 or social <= 0.0):
		_exhaustion_sent = true
		exhausted.emit()

func advance_week() -> void:
	week += 1
	resources_changed.emit()
