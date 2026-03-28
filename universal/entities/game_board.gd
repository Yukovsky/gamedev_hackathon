extends Node2D

#ЗАХАРДКОЖЕНАЯ ЗАЛУПА НУЖНО ПОМЕНЯТЬ

const CELL_SIZE = 90
const START_X = 1080 / 2 - CELL_SIZE
const START_Y = 1800 - (CELL_SIZE * 8) # Позиционируем корабль в нижней трети экрана

func _ready() -> void:
	# Программист 2: Здесь спавн корабля, мусора и интерактивных сущностей
	print("GameBoard Initialized")
	_draw_base_ship()

func _draw_base_ship() -> void:
	# Базовый корабль занимает зону 2x3 (Ядро, Грузовой отсек и Сборщик)
	# Мы просто нарисуем их ColorRect'ами
	
	var layout = [
		Vector2(0, 0), Vector2(1, 0),
		Vector2(0, 1), Vector2(1, 1),
		Vector2(0, 2), Vector2(1, 2)
	]
	
	for pos in layout:
		var rect = ColorRect.new()
		# Выбираем разные цвета для наглядности (Ядро - красное, остальное - синее)
		rect.color = Color(0.2, 0.6, 0.8) # Синий цвет корпуса

		if pos == Vector2(0, 2) or pos == Vector2(1, 2):
			rect.color = Color(0.8, 0.3, 0.3) # Ядро внизу
		
			
		rect.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4) # Отступы для вида сетки
		rect.position = Vector2(START_X + pos.x * CELL_SIZE, START_Y + pos.y * CELL_SIZE)
		add_child(rect)
		
		# Номер ячейки
		var label = Label.new()
		label.text = str(int(pos.x)) + "," + str(int(pos.y))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.add_child(label)
