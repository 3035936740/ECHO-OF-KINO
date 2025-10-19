# translation_manager.gd
class_name KinoTranslationManager

const DEFAULT_LANGUAGE = "en"

static var current_language = DEFAULT_LANGUAGE
static var translations = {}

static func LoadTranslations():
	var file = FileAccess.open("res://translations.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			translations = json.data
			KinoLogger.Success("Translation file loaded successfully")
		else:
			KinoLogger.Error("JSON parsing error: " + json.get_error_message())

static func SetLanguage(lang_code: String):
	if translations.has(lang_code):
		current_language = lang_code
		KinoLogger.Info("Language settings are: " + lang_code)
	else:
		current_language = DEFAULT_LANGUAGE
		KinoLogger.Warn("Unsupported languages: " + lang_code)

static func Translate() -> Dictionary:
	if translations.has(current_language):
		return translations[current_language]
	return {}  # 如果找不到翻译，返回键名

static func getTranslateInfo() -> Dictionary:
	return translations.language

static func _static_init():
	LoadTranslations()
