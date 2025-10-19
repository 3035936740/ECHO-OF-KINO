extends CanvasLayer

@onready var selector: Control = $Selector
@onready var left_arrow: TextureRect = $Selector/Left
@onready var right_arrow: TextureRect = $Selector/Right
@onready var texts: Array[Label] = [
	$Texts/Start,
	$Texts/Option,
	$Texts/Exit
]

@onready var select_sfx: AudioStreamPlayer = $SelectSFX
@onready var confirm_sfx: AudioStreamPlayer = $Confirm

const SELECTOR_DEFAULT_POSITION := Vector2(240.0, 158.0)
var max_texts := 0
var selector_tween: Tween
var current_index := 0

func wrap_index(index: int, length: int) -> int:
	select_sfx.play()
	return (index + length) % length;

const PADDING := 16.0  # 比文字宽高多出的像素
const SELECTOR_MOVE_SPACING: float = 26.0
const MAX_SELECTOR_RESIZE: float = 6.0;

func selector_move(index: int):
	if selector_tween and selector_tween.is_running():
		selector_tween.kill();
		
	selector_tween = create_tween()  # 创建新的 Tween
	selector_tween.play();
	var text := texts[index];
	
	var font := text.get_theme_font("font")
	var text_vector = font.get_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT,-1.0, GlobalDatas.TITLE_TEXTS_SIZE)
	
	var width_text: float = text_vector.x
	
	var padding : float = int((PADDING + width_text) / 2)
	
	selector.size.x = padding * 2
	var selector_pos: Vector2 = Vector2(SELECTOR_DEFAULT_POSITION.x - padding, SELECTOR_DEFAULT_POSITION.y + index * SELECTOR_MOVE_SPACING)	
	selector.position = selector_pos
	
	selector_tween.set_trans(Tween.TRANS_SINE)      # 平滑的正弦缓动
	selector_tween.set_ease(Tween.EASE_IN_OUT)      # 缓入缓出
	
	var pos_temp := selector_pos
	var size_temp := selector.size;
	size_temp.x = size_temp.x + MAX_SELECTOR_RESIZE * 2
	pos_temp.x = pos_temp.x - MAX_SELECTOR_RESIZE
	# KinoLogger.Info(size_temp)
	# KinoLogger.Info(pos_temp)
	
	# 同时开始两个属性的补间
	selector_tween.tween_property(selector, "position", pos_temp, 0.5)
	selector_tween.parallel().tween_property(selector, "size", size_temp, 0.5)
	
	selector_tween.tween_property(selector, "position", selector_pos, 0.5)
	selector_tween.parallel().tween_property(selector, "size", selector.size, 0.5)
	
	# 再回到原状
	selector_tween.set_loops()
	# tween.tween_callback(func(): 
	# 	tween.kill()
	# )
	
	pass

func _ready():
	# 加载语言选项
	var translate = KinoTranslationManager.Translate()
	$Texts/Start.text = translate.title_screen.start
	$Texts/Option.text = translate.title_screen.option
	$Texts/Exit.text = translate.title_screen.exit
	
	var test_msg :String = GlobalDatas.TEST_MESSAGE[randi() % GlobalDatas.TEST_MESSAGE.size()]
	$TestText.text = test_msg
	
	selector_move(current_index);
	max_texts = texts.size();

func handle_select(index: int):
	confirm_sfx.play()
	var text := texts[index];
	if text.has_meta("flash_tween"):
		var old_tween: Tween = text.get_meta("flash_tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	var tween := create_tween()

	var original_color: Color = Color.WHITE
	var flash_color: Color = Color.BLACK  # 或 Color(0, 0, 0)

	# 闪烁三次（白 ↔ 黑）
	for i in range(2):
		tween.tween_property(text, "modulate", flash_color, 0.05)
		tween.tween_property(text, "modulate", original_color, 0.1)
	
	tween.tween_property(text, "modulate", original_color, 0.05)
	tween.tween_callback(func(): 
		text.set_meta("flash_tween", null)
		match index:
			0: # Start
				pass
				# start_game()
			1: # Option
				pass
				# enter_option_menu()
			2: # Exit
				get_tree().quit()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	selector_tween.custom_step(delta)
	var current_index_init := current_index
	
	if Input.is_action_just_pressed("ui_up"):
		current_index = wrap_index(current_index + -1, max_texts)
	if Input.is_action_just_pressed("ui_down"):
		current_index = wrap_index(current_index + 1, max_texts)
	if Input.is_action_just_pressed("ui_accept"):
		handle_select(current_index)
	
	if current_index_init != current_index:
		selector_move(current_index)
