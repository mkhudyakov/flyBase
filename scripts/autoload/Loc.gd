extends Node
## Loc (autoload singleton) — localization. Registers a Russian translation at
## runtime so Godot auto-translates fixed Control text (button/label strings),
## and loads localized campaign text from data/lang_ru.json.
##
## Scope: UI chrome + the full campaign (briefings/tutorials/objectives/quizzes)
## are localized. Procedurally generated explanation logs remain English for now.

## English source string -> Russian. The key must match the on-screen English
## text exactly (Godot looks it up by the displayed string).
const STRINGS_RU := {
	# Menu / general
	"Drosophila Genetics Lab Simulator": "Симулятор генетической лаборатории дрозофилы",
	"A dry-lab, educational genetics simulation": "Образовательный симулятор генетики (сухая лаборатория)",
	"Continue": "Продолжить",
	"New Campaign": "Новая кампания",
	"Sandbox": "Песочница",
	"Challenges": "Испытания",
	"Tutorial Library": "Библиотека обучения",
	"Settings": "Настройки",
	"Quit": "Выход",
	"Menu": "Меню",
	"Back to Menu": "Назад в меню",
	"Back to Dashboard": "Назад к панели",
	"Open Lab": "Открыть лабораторию",
	# Dashboard
	"Lab Dashboard": "Панель лаборатории",
	"Vials": "Пробирки",
	"Flies": "Мухи",
	"Incubators": "Инкубаторы",
	"Incubator:": "Инкубатор:",
	"New vial": "Новая пробирка",
	"Archive": "Архивировать",
	"Breed (50)": "Скрестить (50)",
	"Inspect fly": "Осмотреть муху",
	"Move fly": "Переместить муху",
	"Save Lab": "Сохранить лабораторию",
	"Load Lab": "Загрузить лабораторию",
	"No vial selected": "Пробирка не выбрана",
	"Tools:": "Инструменты:",
	# Tool names
	"Genome": "Геном",
	"Phenotype": "Фенотип",
	"Microscope": "Микроскоп",
	"Development": "Развитие",
	"Cross": "Скрещивание",
	"Statistics": "Статистика",
	"Notebook": "Журнал",
	"Campaign": "Кампания",
	"Population": "Популяция",
	"Equipment": "Оборудование",
	# Screen titles
	"Genotype Debug (Phase 1)": "Отладка генотипа (Фаза 1)",
	"Phenotype Viewer (Phase 2)": "Просмотр фенотипа (Фаза 2)",
	"Microscope Viewer (Phase 3)": "Микроскоп (Фаза 3)",
	"Development Timeline (Phase 4)": "Развитие: хронология (Фаза 4)",
	"Cross Simulator (Phase 5)": "Симулятор скрещивания (Фаза 5)",
	"Statistics (Phase 7)": "Статистика (Фаза 7)",
	"Lab Notebook (Phase 7)": "Лабораторный журнал (Фаза 7)",
	"Population Simulation (Phase 10)": "Симуляция популяции (Фаза 10)",
	"Equipment & Upgrades (Phase 11)": "Оборудование и улучшения (Фаза 11)",
	# Common buttons / fields
	"Run": "Запустить",
	"Run cross": "Запустить скрещивание",
	"Run development": "Запустить развитие",
	"Recompute (fresh roll)": "Пересчитать (заново)",
	"Random seed": "Случайное зерно",
	"Seed": "Зерно",
	"Offspring": "Потомство",
	"Subject": "Объект",
	"Vial:": "Пробирка:",
	"Histogram trait:": "Признак гистограммы:",
	"Temperature": "Температура",
	"Low food": "Мало еды",
	"High crowding": "Высокая скученность",
	"Bottleneck @ gen 4": "Бутылочное горлышко (пок. 4)",
	"Export notebook": "Экспорт журнала",
	"Publish selected": "Опубликовать выбранное",
	"Save & Reload this fly": "Сохранить и перезагрузить муху",
	"Mother (♀)": "Мать (♀)",
	"Father (♂)": "Отец (♂)",
	# Campaign screen
	"Objectives": "Задачи",
	"Start scenario": "Начать сценарий",
	"Check objectives": "Проверить задачи",
	"Complete scenario": "Завершить сценарий",
	"Got it": "Понятно",
	# Settings
	"Audio": "Звук",
	"Master volume": "Общая громкость",
	"Sound effects": "Звуковые эффекты",
	"Ambient music": "Фоновая музыка",
	"Accessibility": "Доступность",
	"High contrast text": "Высокий контраст текста",
	"Reduce motion": "Уменьшить анимацию",
	"Language": "Язык",
	"Tutorial": "Обучение",
	"Start New Game (reset progress)": "Новая игра (сбросить прогресс)",
	"Reset everything": "Сбросить всё",
	"This resets your lab, campaign progress, and economy. Settings are kept. Continue?":
		"Это сбросит лабораторию, прогресс кампании и экономику. Настройки сохранятся. Продолжить?",
	"This is a simplified educational dry-lab simulation inspired by Drosophila genetics. It does not simulate the full genome, does not provide real gene-editing instructions, and must not be used for real biological or medical decisions.":
		"Это упрощённый образовательный симулятор сухой лаборатории по мотивам генетики дрозофилы. Он не моделирует полный геном, не даёт реальных инструкций по редактированию генов и не должен использоваться для настоящих биологических или медицинских решений.",
	# Code-set label templates (translated via tr() in code)
	"Temperature: %.0f °C": "Температура: %.0f °C",
	"UI scale: %d%%": "Масштаб интерфейса: %d%%",
	# Campaign status lines (code-set)
	"Completed ✓": "Завершено ✓",
	"Locked — complete the prerequisite scenario first.": "Заблокировано — сначала пройдите предыдущий сценарий.",
	"Scenario complete.": "Сценарий завершён.",
	"Locked.": "Заблокировано.",
	"Scenario in progress — breed in the lab, then Check objectives.":
		"Сценарий идёт — скрещивайте мух в лаборатории, затем нажмите «Проверить задачи».",
	"Press Start to begin this scenario.": "Нажмите «Начать сценарий», чтобы приступить.",
	"Correct!": "Верно!",
	"Not quite — try again.": "Не совсем — попробуйте ещё раз.",
	"Scenario completed — new content unlocked.": "Сценарий пройден — открыт новый контент.",
	"All objectives met! Press Complete scenario.": "Все задачи выполнены! Нажмите «Завершить сценарий».",
	"Restart scenario": "Перезапустить сценарий",
}

var _ru := Translation.new()
var _ru_scenarios := {}

func _ready() -> void:
	_ru.locale = "ru"
	for k in STRINGS_RU:
		_ru.add_message(k, STRINGS_RU[k])
	TranslationServer.add_translation(_ru)

	var data: Variant = DataLoader.load_json("res://data/lang_ru.json")
	if data is Dictionary and data.has("scenarios"):
		_ru_scenarios = data["scenarios"]

	apply()

## Applies the saved language to the TranslationServer.
func apply() -> void:
	TranslationServer.set_locale(Settings.language)

func set_language(code: String) -> void:
	Settings.language = code
	Settings.save_settings()
	TranslationServer.set_locale(code)

func is_russian() -> bool:
	return Settings.language == "ru"

# --- Campaign localization ---------------------------------------------------

## Localized scenario field (title/briefing). Falls back to English.
func scenario_text(scenario: Dictionary, field: String) -> String:
	if is_russian():
		var loc: Dictionary = _ru_scenarios.get(String(scenario.get("id", "")), {})
		if loc.has(field):
			return String(loc[field])
	return String(scenario.get(field, ""))

## Localized tutorial step list.
func scenario_tutorial(scenario: Dictionary) -> Array:
	if is_russian():
		var loc: Dictionary = _ru_scenarios.get(String(scenario.get("id", "")), {})
		if loc.has("tutorial"):
			return loc["tutorial"]
	return scenario.get("tutorial", [])

## Localized objective field (desc/question) by index; falls back to English.
func objective_text(scenario: Dictionary, index: int, field: String) -> String:
	if is_russian():
		var loc: Dictionary = _ru_scenarios.get(String(scenario.get("id", "")), {})
		var objs: Array = loc.get("objectives", [])
		if index < objs.size() and objs[index] is Dictionary and objs[index].has(field):
			return String(objs[index][field])
	var en_objs: Array = scenario.get("objectives", [])
	return String(en_objs[index].get(field, "")) if index < en_objs.size() else ""

## Localized quiz option list for an objective; falls back to English options.
func objective_options(scenario: Dictionary, index: int) -> Array:
	if is_russian():
		var loc: Dictionary = _ru_scenarios.get(String(scenario.get("id", "")), {})
		var objs: Array = loc.get("objectives", [])
		if index < objs.size() and objs[index] is Dictionary and objs[index].has("options"):
			return objs[index]["options"]
	var en_objs: Array = scenario.get("objectives", [])
	return en_objs[index].get("options", []) if index < en_objs.size() else []
