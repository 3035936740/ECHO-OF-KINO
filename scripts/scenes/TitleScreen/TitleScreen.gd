extends CanvasLayer

## -----------------------------------------------------------------------------
## 菜单项枚举 (Enums for Readability)
## -----------------------------------------------------------------------------

enum MainMenuIndex {
	START = 0,
	OPTION = 1,
	EXIT = 2,
}

enum OptionMenuIndex {
	RESOLUTION = 0,
	LANGUAGE = 1,
	RETURN = 2,
}

## -----------------------------------------------------------------------------
## 节点和配置 (Nodes and Configuration)
## -----------------------------------------------------------------------------

# 核心 UI 节点
@onready var selector: Control = $Root/Selector
@onready var left_arrow: TextureRect = $Root/Selector/Left
@onready var right_arrow: TextureRect = $Root/Selector/Right

# 文本列表
@onready var main_texts: Array[Label] = [
	$Root/MainTexts/Start,
	$Root/MainTexts/Option,
	$Root/MainTexts/Exit
]

@onready var Arrows: Array[TextureRect] = [
	$Root/Selector/Right,
	$Root/Selector/Left
]

@onready var option_texts: Array[Label] = [
	$Root/OptionTexts/Resolutions,
	$Root/OptionTexts/Language,
	$Root/OptionTexts/Return
]

# 根节点
@onready var root_main_texts_node : Control = $Root/MainTexts
@onready var root_option_texts_node : Control = $Root/OptionTexts

@onready var test_text : Label = $Root/TestText

# 音效节点
@onready var select_sfx: AudioStreamPlayer = $Root/SelectSFX
@onready var confirm_sfx: AudioStreamPlayer = $Root/Confirm

## -----------------------------------------------------------------------------
## 状态和数据 (State Variables and Data)
## -----------------------------------------------------------------------------

var is_option :bool = false
var is_lr_select :bool = false
var curr_langcode: String
var langcode_index: int
var scale_steps_index: int
var leftright_arrow_indexs: Array[int] = []

# 动画和配置
var max_texts := 0
var selector_tween: Tween
var current_index := 0
var config := OptionManager.new()

## -----------------------------------------------------------------------------
## 常量 (Constants)
## -----------------------------------------------------------------------------

const SELECTOR_MAIN_START_POS := Vector2(240.0, 158.0)
const SELECTOR_OPTION_START_POS := Vector2(240.0, 150.0)

const TEXT_PADDING_EXTRA := 16.0

const MAIN_MOVE_SPACING: float = 26.0
const OPTION_MOVE_SPACING: float = 28.0
const SELECTOR_RESIZE_MAX_OFFSET: float = 6.0

## -----------------------------------------------------------------------------
## 导航和索引 (Navigation and Indexing)
## -----------------------------------------------------------------------------

func _get_wrapped_index(index: int, length: int) -> int:
	select_sfx.play()
	return (index + length) % length

func _update_selection_mode_and_index(add: int):
	current_index = _get_wrapped_index(current_index + add, max_texts)
	
	var lr_change: bool = false
	if leftright_arrow_indexs.has(current_index):
		lr_change = true
	else:
		lr_change = false
		
	is_lr_select = lr_change
	flip_arrow(lr_change)

## -----------------------------------------------------------------------------
## 选择器动画 (Selector Animation)
## -----------------------------------------------------------------------------

func selector_move(index: int):
	# 瞬移逻辑: 在 Godot 4 中，杀掉并重新创建 Tween 以实现即时位置更新
	if selector_tween and selector_tween.is_running():
		selector_tween.kill()
		
	selector_tween = create_tween()
	selector_tween.play()
	
	var text : Label
	var selector_def_pos: Vector2
	var selector_move_spa: float
	
	if is_option:
		selector_def_pos = SELECTOR_OPTION_START_POS
		selector_move_spa = OPTION_MOVE_SPACING
		text = option_texts[index]
	else:
		selector_def_pos = SELECTOR_MAIN_START_POS
		selector_move_spa = MAIN_MOVE_SPACING
		text = main_texts[index]
	
	var font := text.get_theme_font("font")
	# 使用 Godot 4 的 API
	var text_vector = font.get_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, GlobalDatas.TITLE_TEXTS_SIZE)
	
	var width_text: float = text_vector.x
	
	# 注意: 你的原代码将 float 结果强制转换为 int。保持此行为
	var padding : float = int((TEXT_PADDING_EXTRA + width_text) / 2.0)
	
	selector.size.x = padding * 2
	var selector_pos: Vector2 = Vector2(selector_def_pos.x - padding, selector_def_pos.y + index * selector_move_spa)	
	
	# **关键：瞬移逻辑**
	# 你的代码依赖 Tween 启动前 selector.position 已经更新到目标附近
	selector.position = selector_pos # 保持瞬移设置
	
	selector_tween.set_trans(Tween.TRANS_SINE)
	selector_tween.set_ease(Tween.EASE_IN_OUT)
	
	var pos_temp := selector_pos
	var size_temp := selector.size
	size_temp.x = size_temp.x + SELECTOR_RESIZE_MAX_OFFSET * 2
	pos_temp.x = pos_temp.x - SELECTOR_RESIZE_MAX_OFFSET
	
	# 同时开始两个属性的补间 (呼吸动画)
	selector_tween.tween_property(selector, "position", pos_temp, 0.5)
	selector_tween.parallel().tween_property(selector, "size", size_temp, 0.5)
	
	# 缩小回原状
	selector_tween.tween_property(selector, "position", selector_pos, 0.5)
	selector_tween.parallel().tween_property(selector, "size", selector.size, 0.5)
	
	# 再回到原状，并循环
	selector_tween.set_loops()

## -----------------------------------------------------------------------------
## 配置和数据加载 (Configuration and Data)
## -----------------------------------------------------------------------------

func _load_and_apply_config():
	# 加载语言选项
	KinoTranslationManager.SetLanguage(curr_langcode)
	config.setValue("game","language", curr_langcode)
	config.setValue("video", "scale_steps", scale_steps_index)
	
	var translate = KinoTranslationManager.Translate()
	# main
	main_texts[MainMenuIndex.START].text = translate.title_screen.start
	main_texts[MainMenuIndex.OPTION].text = translate.title_screen.option
	main_texts[MainMenuIndex.EXIT].text = translate.title_screen.exit
	
	var language_infos := KinoTranslationManager.getTranslateInfo()
	var keys_list = language_infos.keys()

	for i in range(keys_list.size()):
		var key = keys_list[i]
		if key == curr_langcode:
			langcode_index = i
	
	var display_lan: String = language_infos[curr_langcode]
	
	var resolutions := OptionManager.RESOLUTIONS
	var resolution :Vector2i = resolutions[0]
	if scale_steps_index < resolutions.size():
		resolution = resolutions[scale_steps_index]
		
	DisplayServer.window_set_size(resolution)
	KinoUtils.setWindowCenter()
	# option
	option_texts[OptionMenuIndex.RESOLUTION].text = "%d x %d" % [resolution.x, resolution.y] # 使用枚举
	option_texts[OptionMenuIndex.LANGUAGE].text = display_lan # 使用枚举
	option_texts[OptionMenuIndex.RETURN].text = translate.title_screen.option_details.return_main # 使用枚举

func flip_arrow(flip: bool):
	if flip:
		Arrows[0].flip_h = true
		Arrows[1].flip_h = false
	else:
		Arrows[0].flip_h = false
		Arrows[1].flip_h = true

func _change_scale_step(add_index: int):
	var scale_count := OptionManager.RESOLUTIONS.size()
	scale_steps_index = scale_steps_index + add_index
	scale_steps_index = (scale_steps_index + scale_count) % scale_count
	_load_and_apply_config()

func _change_language_code(add_index: int):
	var language_infos := KinoTranslationManager.getTranslateInfo()
	
	var keys_list = language_infos.keys()
	var lang_count := keys_list.size()
	langcode_index = langcode_index + add_index
	langcode_index = (langcode_index + lang_count) % lang_count
	curr_langcode = keys_list[langcode_index]
	_load_and_apply_config()

## -----------------------------------------------------------------------------
## 回调函数 (Callback Functions)
## -----------------------------------------------------------------------------

func _handle_option_selection_callback(text:Label, index: int, add_value: int = 1):
	text.set_meta("flash_tween", null)
	match index:
		OptionMenuIndex.RESOLUTION:
			_change_scale_step(add_value)
		OptionMenuIndex.LANGUAGE:
			_change_language_code(add_value)
		OptionMenuIndex.RETURN:
			_return_to_main_control()
	
	selector_move(current_index)
			
func _handle_main_selection_callback(text:Label, index: int):
	text.set_meta("flash_tween", null)
	match index:
		MainMenuIndex.START:
			pass
		MainMenuIndex.OPTION:
			_enter_option_control()
		MainMenuIndex.EXIT:
			get_tree().quit()

func _execute_selection_animation(index: int):
	confirm_sfx.play()
	var text :Label
	var call_funstr : String
	if is_option:
		call_funstr = "_handle_option_selection_callback"
		text = option_texts[index]
	else:
		call_funstr = "_handle_main_selection_callback"
		text = main_texts[index]
		
	var confirm_call: Callable = Callable(self, call_funstr).bind(text, index)
	
	if text.has_meta("flash_tween"):
		var old_tween: Tween = text.get_meta("flash_tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	var tween := create_tween()
	var original_color: Color = Color.WHITE
	var flash_color: Color = Color.BLACK

	# 闪烁2次（白 ↔ 黑）
	for i in range(2):
		tween.tween_property(text, "modulate", flash_color, 0.05)
		tween.tween_property(text, "modulate", original_color, 0.1)
	
	tween.tween_property(text, "modulate", original_color, 0.05)
	
	tween.tween_callback(confirm_call)

## -----------------------------------------------------------------------------
## 状态控制 (State Control)
## -----------------------------------------------------------------------------

func _enter_option_control():
	root_main_texts_node.hide()
	is_option = true
	current_index = OptionMenuIndex.RESOLUTION
	is_lr_select = true
	flip_arrow(true)
	leftright_arrow_indexs = [OptionMenuIndex.RESOLUTION, OptionMenuIndex.LANGUAGE]
	selector_move(current_index)
	max_texts = option_texts.size()
	root_option_texts_node.show()
	
func _return_to_main_control():
	root_main_texts_node.show()
	is_option = false
	current_index = MainMenuIndex.OPTION
	is_lr_select = false
	flip_arrow(false)
	leftright_arrow_indexs = []
	selector_move(current_index)
	max_texts = main_texts.size()
	root_option_texts_node.hide()

## -----------------------------------------------------------------------------
## 主输入循环 (Main Input Loops)
## -----------------------------------------------------------------------------

func main_control(delta: float):
	selector_tween.custom_step(delta)
	var current_index_init := current_index
	
	if Input.is_action_just_pressed("ui_up"):
		_update_selection_mode_and_index(-1)
	if Input.is_action_just_pressed("ui_down"):
		_update_selection_mode_and_index(1)
		
	if Input.is_action_just_pressed("ui_accept"):
		_execute_selection_animation(current_index)
	
	if current_index_init != current_index:
		selector_move(current_index)

func main_option_control(delta: float):
	selector_tween.custom_step(delta)
	var current_index_init := current_index
	
	if Input.is_action_just_pressed("ui_up"):
		_update_selection_mode_and_index(-1)
	if Input.is_action_just_pressed("ui_down"):
		_update_selection_mode_and_index(1)
		
	if is_lr_select:
		if Input.is_action_just_pressed("ui_right"):
			select_sfx.play()
			_handle_option_selection_callback(option_texts[current_index], current_index, 1)
		if Input.is_action_just_pressed("ui_left"):
			select_sfx.play()
			_handle_option_selection_callback(option_texts[current_index], current_index, -1)
			
	if Input.is_action_just_pressed("ui_accept"):
		_execute_selection_animation(current_index)
	
	if current_index_init != current_index:
		selector_move(current_index)
		
## -----------------------------------------------------------------------------
## 生命周期 (Lifecycle)
## -----------------------------------------------------------------------------

func _ready():
	scale_steps_index = config.getValue("video", "scale_steps")
	curr_langcode = config.getValue("game", "language")
	_load_and_apply_config()
	
	var test_msg :String = GlobalDatas.TEST_MESSAGE[randi() % GlobalDatas.TEST_MESSAGE.size()]
	test_text.text = test_msg
	
	selector_move(current_index)
	max_texts = main_texts.size()

func _process(delta: float) -> void:
	if is_option:
		main_option_control(delta)
	else:
		main_control(delta)
