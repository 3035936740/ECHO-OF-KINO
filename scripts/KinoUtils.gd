class_name KinoUtils

static func setWindowCenter() -> void:
	# 获取屏幕尺寸
	var screen_size = DisplayServer.screen_get_size()
	# 获取窗口尺寸
	var window_size = DisplayServer.window_get_size()
	# 计算居中位置
	var pos = (screen_size - window_size) / 2
	# 设置窗口位置
	DisplayServer.window_set_position(pos)
