# logger.gd
class_name KinoLogger

const COLORS = {
	"RESET": "\u001b[0m",
	"BLACK": "\u001b[30m",
	"RED": "\u001b[31m",
	"GREEN": "\u001b[32m",
	"YELLOW": "\u001b[33m",
	"BLUE": "\u001b[34m",
	"MAGENTA": "\u001b[35m",
	"CYAN": "\u001b[36m",
	"WHITE": "\u001b[37m",
	"GRAY": "\u001b[90m",
	"BRIGHT_RED": "\u001b[91m",
	"BRIGHT_GREEN": "\u001b[92m",
	"BRIGHT_YELLOW": "\u001b[93m",
	"BRIGHT_BLUE": "\u001b[94m",
	"BRIGHT_MAGENTA": "\u001b[95m",
	"BRIGHT_CYAN": "\u001b[96m"
}

const LEVEL_COLORS = {
	"DEBUG": COLORS.GRAY,
	"INFO": COLORS.BRIGHT_CYAN,
	"WARN": COLORS.BRIGHT_YELLOW,
	"ERROR": COLORS.BRIGHT_RED,
	"SUCCESS": COLORS.BRIGHT_GREEN
}

# 日志级别
enum LOG_LEVEL {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	SUCCESS = 4
}

static var current_level = LOG_LEVEL.DEBUG # 日志最低等级
static var enable_colors = false # 是否启用颜色控制台日志
static var enable_file_logging = true # 是否启用日志
static var max_log_files = 5 # 最大日志文件
static var max_file_size = 1024 * 1024  # 日志最大输出

static var log_directory = "res://logs/"
static var current_log_file: FileAccess

static func get_log_filename() -> String:
	var date = Time.get_date_string_from_system()
	return "%s.log" % date;

static func rotate_log_files():
	if not enable_file_logging:
		return
		
	var dir = DirAccess.open(log_directory)
	if dir:
		var files = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".log") && !dir.current_is_dir():
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		# 按修改时间排序
		files.sort_custom(func(a, b): 
			var time_a = FileAccess.get_modified_time(log_directory + a)
			var time_b = FileAccess.get_modified_time(log_directory + b)
			return time_a > time_b
		)
		
		# 删除最旧的文件
		while files.size() >= max_log_files:
			var oldest_file = files.pop_back()
			var remove_result = dir.remove(oldest_file)
			if remove_result == OK:
				Debug("Rotated log file: " + oldest_file);

static func setup_current_log_file():
	if not enable_file_logging:
		return

	var log_path = log_directory + get_log_filename()
	
	# 检查文件大小，如果太大则轮转
	if FileAccess.file_exists(log_path):
		var test_file = FileAccess.open(log_path, FileAccess.READ)
		if test_file && test_file.get_length() > max_file_size:
			rotate_log_files()
			test_file = null
	
	current_log_file = FileAccess.open(log_path, FileAccess.WRITE_READ)
	if current_log_file:
		current_log_file.seek_end()
		# 写入日志文件头
		var header = "=== Log Session Started at %s ===\n" % Time.get_datetime_string_from_system()
		if current_log_file.get_position() == 0:  # 新文件才写头部
			current_log_file.store_string(header)
		current_log_file.flush()
	else:
		push_warning("Failed to open log file: " + log_path);

static func setup_log_directory():
	# 获取当前项目目录
	var project_path = ProjectSettings.globalize_path("res://")
	
	# 确保日志目录存在
	var dir = DirAccess.open(project_path)
	if dir:
		if not dir.dir_exists("logs"):
			var result = dir.make_dir("logs")
			if result != OK:
				push_error("Failed to create logs directory: " + str(result))
				enable_file_logging = false
				return;

static func _write_to_log_file(message: String):
	if not enable_file_logging:
		return
	
	if current_log_file == null or not current_log_file.is_open():
		setup_current_log_file()
		if current_log_file == null:
			return
	
	if current_log_file and current_log_file.is_open():
		current_log_file.store_string(message)
		current_log_file.flush();

static func _format_console_message(timestamp: String, level: String, message: String) -> String:
	var log_message = "[%s] %s: %s" % [timestamp, level, message]
	# 添加颜色
	if enable_colors:
		var level_color = LEVEL_COLORS.get(level, COLORS.WHITE)
		log_message = level_color + log_message + COLORS.RESET
	
	return log_message;

static func _format_file_message(timestamp: String, level: String, message: String) -> String:
	var log_message = "[%s] %s: %s" % [timestamp, level, message]
	
	return log_message + "\n"

static func Success(message: Variant):
	if current_level <= LOG_LEVEL.SUCCESS:
		Pushlog("SUCCESS", str(message))

static func Debug(message: Variant):
	if current_level <= LOG_LEVEL.DEBUG:
		Pushlog("DEBUG", str(message))

static func Info(message: Variant):
	if current_level <= LOG_LEVEL.INFO:
		Pushlog("INFO", str(message))

static func Warn(message: Variant):
	if current_level <= LOG_LEVEL.WARN:
		Pushlog("WARN", str(message))

static func Error(message: Variant):
	if current_level <= LOG_LEVEL.ERROR:
		Pushlog("ERROR", str(message))

static func EnableFileLogging(enabled: bool):
	enable_file_logging = enabled
	if enabled:
		setup_log_directory()

static func SetMaxLogFiles(count: int):
	max_log_files = count

static func SetMaxFileSize(size_kb: int):
	max_file_size = size_kb * 1024

# 报告生成方法
static func GenerateReport() -> String:
	var report = "=== Game Log Report ===\n"
	report += "Generated at: %s\n" % Time.get_datetime_string_from_system()
	report += "Log level: %s\n" % LOG_LEVEL.keys()[current_level]
	report += "File logging: %s\n" % ("Enabled" if enable_file_logging else "Disabled")
	report += "Log directory: %s\n" % ProjectSettings.globalize_path(log_directory)
	
	if enable_file_logging:
		var log_path = log_directory + get_log_filename()
		if FileAccess.file_exists(log_path):
			var file = FileAccess.open(log_path, FileAccess.READ)
			if file:
				report += "Current log file size: %d bytes\n" % file.get_length()
				file.close()
		else:
			report += "Current log file: Not created yet\n"
	
	return report

# 获取日志文件路径（便于用户查看）
static func GetLogFilePath() -> String:
	if enable_file_logging:
		return ProjectSettings.globalize_path(log_directory + get_log_filename())
	return "File logging disabled"

# 打开日志目录（便于用户查看）
static func OpenLogDirectory():
	var absolute_path = ProjectSettings.globalize_path(log_directory)
	OS.shell_open(absolute_path)

static func Pushlog(level: String, message: String):
	var timestamp = Time.get_time_string_from_system();
	
	var console_message = _format_console_message(timestamp, level, message)
	
	# 使用 Godot 内置打印
	print(console_message)
	if enable_file_logging:
		var file_message = _format_file_message(timestamp, level, message);
		_write_to_log_file(file_message);
	
	# 错误级别额外输出到 stderr
	if level == "ERROR":
		push_error(console_message)
	elif level == "WARN":
		push_warning(console_message)

# 在游戏启动时初始化
static func Initialize():
	setup_log_directory()
	Info("Logger system initialized")
	Info("Log directory: " + ProjectSettings.globalize_path(log_directory))
	Info(GenerateReport())

# 自动初始化
static func _static_init():
	Initialize()
