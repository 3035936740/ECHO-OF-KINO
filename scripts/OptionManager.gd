extends RefCounted
class_name OptionManager

const DEFAULT_WIDTH: int = 480
const DEFAULT_HEIGHT: int = 270

const CONFIG_PATH := "res://config.cfg"
var config := ConfigFile.new()

const DEFAULT_SCALE_STEPS := 1

const SCALE_STEPS := [DEFAULT_SCALE_STEPS, 1.5, 2, 2.5, 3.0, 3.5, 4.0]
const RESOLUTIONS : Array[Vector2i] = [
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[0], DEFAULT_HEIGHT * SCALE_STEPS[0]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[1], DEFAULT_HEIGHT * SCALE_STEPS[1]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[2], DEFAULT_HEIGHT * SCALE_STEPS[2]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[3], DEFAULT_HEIGHT * SCALE_STEPS[3]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[4], DEFAULT_HEIGHT * SCALE_STEPS[4]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[5], DEFAULT_HEIGHT * SCALE_STEPS[5]),
	Vector2i(DEFAULT_WIDTH * SCALE_STEPS[6], DEFAULT_HEIGHT * SCALE_STEPS[6])
]

# 默认配置（初次创建时使用）
const DEFAULTS := {
	"video": {
		"scale_steps": DEFAULT_SCALE_STEPS
	},
	"game": {
		"language": "en",
		"debug": false
	}
}

func _init() -> void:
	loadConfig()
	
func loadConfig() -> void:
	var err = config.load(CONFIG_PATH)
	
	if err != OK:
		KinoLogger.Info("[OptionManager] Config not found, creating new one.")
		# 写入默认配置
		for section in DEFAULTS.keys():
			for key in DEFAULTS[section].keys():
				config.set_value(section, key, DEFAULTS[section][key])
		saveConfig()
	else:
		KinoLogger.Success("[OptionManager] Config loaded successfully.")

func saveConfig() -> void:
	var err = config.save(CONFIG_PATH)
	if err != OK:
		KinoLogger.Error("[OptionManager] Failed to save config file.")
	else:
		KinoLogger.Info("[OptionManager] Config saved to %s" % CONFIG_PATH)

# 获取配置项
func getValue(section: String, key: String, default_value: Variant = null) -> Variant:
	if config.has_section_key(section, key):
		return config.get_value(section, key)
	elif default_value != null:
		return default_value
	elif section in DEFAULTS and key in DEFAULTS[section]:
		return DEFAULTS[section][key]
	else:
		return null

# 设置配置项（并立即保存）
func setValue(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	saveConfig()
