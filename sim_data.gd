extends Node

var ICTemperature: Array = []

const nX = 512
const nR = 16


func _init() -> void:
	ICTemperature.resize(nX)
	for i in range(nX):
		var row: Array = []
		row.resize(nR)
		row.fill(0.0)
		ICTemperature[i] = row
