extends Node

# constants

const nX = 512
const nR = 16
const R = 8314  # Gas constant
const UpdateDebounceTime = 0.25

var UpdateTimer: Timer  # Debounces recalculations
var ParamsDidChange: bool = false
var IcsDidChange: bool = false

# parameters and ICs

var ICTemperature: Array = []

var g: float = 9.81:
	set = _set_g,
	get = _get_g  # Gravity
var mm: float = 28.965:
	set = _set_mm,
	get = _get_mm  # Air molar mass
var cp: float = 1005:
	set = _set_cp,
	get = _get_cp  # Air isobaric heat cap
var Po: float = 101325:
	set = _set_Po,
	get = _get_Po  # Surf pressure
var Pt: float = 5000:
	set = _set_Pt,
	get = _get_Pt  # Tropopause lid pressure

## derived params, don't write to these
var Rspec: float
var kappa: float
var levels: Array = []  # There are 17 of these
var halfLevels: Array = []  # There are 16 of these

# simulation data

var StaticStability: Array = []
var Exner: Array = []

# signals

signal param_update
signal ic_update

# methods


func _init() -> void:
	ICTemperature.resize(nX)
	for i in range(nX):
		var row: Array = []
		row.resize(nR)
		row.fill(0.0)
		ICTemperature[i] = row
		
	calc_levels()

	UpdateTimer = Timer.new()
	UpdateTimer.one_shot = true
	UpdateTimer.autostart = true


func _enter_tree():
	get_tree().root.add_child.call_deferred(UpdateTimer)


func _set_g(p) -> void:
	g = clamp(p, 0.01, 20.0)
	ParamsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)


func _get_g() -> float:
	return g


func _set_mm(p) -> void:
	mm = clamp(p, 1.0, 100.0)
	ParamsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)


func _get_mm() -> float:
	return mm


func _set_cp(p) -> void:
	cp = clamp(p, 1.0, 10000.0)
	ParamsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)


func _get_cp() -> float:
	return cp


func _set_Po(p) -> void:
	Po = clamp(p, Pt, 1e6)
	ParamsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)


func _get_Po() -> float:
	return Po


func _set_Pt(p) -> void:
	Pt = clamp(p, 1.0, Po)
	ParamsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)


func _get_Pt() -> float:
	return Pt


func _process(_delta):
	if UpdateTimer.time_left == 0 and (ParamsDidChange or IcsDidChange):
		if ParamsDidChange:
			recalc_params()
			IcsDidChange = true
			ParamsDidChange = false

		if IcsDidChange:
			recalc_ref_state()
			IcsDidChange = false

func calc_levels():
	levels.resize(nR+1)
	halfLevels.resize(nR)
	levels[0] = Pt
	for i in range(1, nR+1):
		levels[i] = (i * (Po - Pt) / nR)
		halfLevels[i-1] = (levels[i] + levels[i-1]) / 2.0


func recalc_params():
	print("Recalculating derived parameters")
	Rspec = R / mm
	kappa = Rspec / cp
	calc_levels()

	emit_signal("param_update")


func recalc_ref_state():
	print("Recalculating reference atmosphere")
	emit_signal("ic_update")


func set_ics_changed():
	IcsDidChange = true
	UpdateTimer.start(UpdateDebounceTime)
