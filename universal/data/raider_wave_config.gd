extends Resource
class_name RaiderWaveConfig
## Конфигурация волн налётчиков в зависимости от количества построек.
## Data-Driven подход: баланс редактируется в Inspector, не в коде.

@export var waves: Array[RaiderWaveRow] = []


func get_wave_for_buildings(buildings_count: int) -> RaiderWaveRow:
	for wave in waves:
		if buildings_count >= wave.buildings_min and buildings_count <= wave.buildings_max:
			return wave
	
	if waves.is_empty():
		return null
	
	return waves[waves.size() - 1]
