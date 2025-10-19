extends Node
class_name OptionManager

const DEFAULT_WIDTH: int = 480
const DEFAULT_HEIGHT: int = 270

const CONFIG_PATH := "res://config.cfg"
var config := ConfigFile.new()

const SCALE_STEPS := [1, 2, 3, 4]
var RESOLUTIONS : Array[Vector2i] = SCALE_STEPS.map(func(scale):
	return Vector2i(DEFAULT_WIDTH * scale, DEFAULT_HEIGHT * scale)
)

# 默认配置（初次创建时使用）
const DEFAULTS := {
	"video": {
		"resolution": Vector2i(DEFAULT_WIDTH, DEFAULT_HEIGHT)
	},
	"game": {
		"language": "en"
	}
}


func _ready() -> void:
	load_config()


func load_config() -> void:
	var err = config.load(CONFIG_PATH)
	
	if err != OK:
		print("[OptionManager] Config not found, creating new one.")
		# 写入默认配置
		for section in DEFAULTS.keys():
			for key in DEFAULTS[section].keys():
				config.set_value(section, key, DEFAULTS[section][key])
		save_config()
	else:
		print("[OptionManager] Config loaded successfully.")


func save_config() -> void:
	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_error("[OptionManager] Failed to save config file.")
	else:
		print("[OptionManager] Config saved to %s" % CONFIG_PATH)


# 获取配置项
func get_value(section: String, key: String, default_value: Variant = null) -> Variant:
	if config.has_section_key(section, key):
		return config.get_value(section, key)
	elif default_value != null:
		return default_value
	elif section in DEFAULTS and key in DEFAULTS[section]:
		return DEFAULTS[section][key]
	else:
		return null


# 设置配置项（并立即保存）
func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_config()
