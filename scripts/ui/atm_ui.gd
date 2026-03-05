extends CanvasLayer

# ---------------------------------------------------------------------------
# ATM / Deposit Machine UI
#
# BANK        — safe storage, never lost on death (hub_credits)
# ON HAND     — scrap the player is currently carrying (wallet_credits)
#
# DEPOSIT  moves ON HAND → BANK
# WITHDRAW moves BANK → ON HAND
# ---------------------------------------------------------------------------

var _bank_label:   Label    = null
var _hand_label:   Label    = null
var _amount_label: Label    = null
var _custom_input: LineEdit = null

var _transfer_amount: int = 0

const STEP_SMALL := 10
const STEP_LARGE := 100

func _ready() -> void:
	layer        = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func _build_ui() -> void:
	var bg              := ColorRect.new()
	bg.color             = Color(0, 0, 0, 0.65)
	bg.anchor_right      = 1.0
	bg.anchor_bottom     = 1.0
	bg.mouse_filter      = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel             := PanelContainer.new()
	panel.anchor_left      = 0.5
	panel.anchor_top       = 0.5
	panel.anchor_right     = 0.5
	panel.anchor_bottom    = 0.5
	panel.offset_left      = -200.0
	panel.offset_top       = -160.0
	panel.offset_right     =  200.0
	panel.offset_bottom    =  160.0
	bg.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title      := Label.new()
	title.text      = "SCRAP DEPOSIT MACHINE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Balance display — two rows
	_bank_label = Label.new()
	_bank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_bank_label)

	_hand_label = Label.new()
	_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hand_label)

	vbox.add_child(HSeparator.new())

	# Transfer amount row
	var amt_row := HBoxContainer.new()
	amt_row.alignment = BoxContainer.ALIGNMENT_CENTER
	amt_row.add_theme_constant_override("separation", 6)
	vbox.add_child(amt_row)

	var amt_lbl      := Label.new()
	amt_lbl.text      = "AMOUNT:"
	amt_row.add_child(amt_lbl)

	_add_btn(amt_row, "-100", func(): _adjust_amount(-STEP_LARGE))
	_add_btn(amt_row, "-10",  func(): _adjust_amount(-STEP_SMALL))

	_amount_label = Label.new()
	_amount_label.custom_minimum_size = Vector2(80, 0)
	_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt_row.add_child(_amount_label)

	_add_btn(amt_row, "+10",  func(): _adjust_amount(STEP_SMALL))
	_add_btn(amt_row, "+100", func(): _adjust_amount(STEP_LARGE))

	# Custom input row
	var custom_row := HBoxContainer.new()
	custom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	custom_row.add_theme_constant_override("separation", 6)
	vbox.add_child(custom_row)

	_custom_input = LineEdit.new()
	_custom_input.placeholder_text    = "Custom amount..."
	_custom_input.custom_minimum_size = Vector2(140, 0)
	_custom_input.text_submitted.connect(_on_custom_submitted)
	custom_row.add_child(_custom_input)

	_add_btn(custom_row, "SET", func(): _on_custom_submitted(_custom_input.text))

	vbox.add_child(HSeparator.new())

	# Deposit / Withdraw row
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	vbox.add_child(action_row)

	var dep_btn := Button.new()
	dep_btn.text = "DEPOSIT\n(ON HAND → BANK)"
	dep_btn.pressed.connect(_on_deposit)
	action_row.add_child(dep_btn)

	var wth_btn := Button.new()
	wth_btn.text = "WITHDRAW\n(BANK → ON HAND)"
	wth_btn.pressed.connect(_on_withdraw)
	action_row.add_child(wth_btn)

	# Close
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)

func _add_btn(parent: Node, text: String, cb: Callable) -> void:
	var b      := Button.new()
	b.text      = text
	b.pressed.connect(cb)
	parent.add_child(b)

# ---------------------------------------------------------------------------
# Open / close
# ---------------------------------------------------------------------------
func open() -> void:
	_transfer_amount  = 0
	_custom_input.text = ""
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()

# ---------------------------------------------------------------------------
# Transfer amount controls
# ---------------------------------------------------------------------------
func _adjust_amount(delta: int) -> void:
	_transfer_amount = maxi(_transfer_amount + delta, 0)
	_refresh()

func _on_custom_submitted(text: String) -> void:
	_transfer_amount = maxi(text.to_int(), 0)
	_custom_input.text = ""
	_refresh()

# ---------------------------------------------------------------------------
# Deposit / Withdraw
# ---------------------------------------------------------------------------
func _on_deposit() -> void:
	# Move from wallet to bank — capped by what the player actually has on hand
	var amount := mini(_transfer_amount, UpgradeManager.wallet_credits)
	if amount <= 0:
		return
	UpgradeManager.wallet_credits -= amount
	UpgradeManager.hub_credits    += amount
	EventBus.credits_changed.emit(UpgradeManager.wallet_credits)
	SaveManager.save()
	_refresh()

func _on_withdraw() -> void:
	# Move from bank to wallet — capped by bank balance
	var amount := mini(_transfer_amount, UpgradeManager.hub_credits)
	if amount <= 0:
		return
	UpgradeManager.hub_credits    -= amount
	UpgradeManager.wallet_credits += amount
	EventBus.credits_changed.emit(UpgradeManager.wallet_credits)
	SaveManager.save()
	_refresh()

# ---------------------------------------------------------------------------
# Refresh display
# ---------------------------------------------------------------------------
func _refresh() -> void:
	_bank_label.text   = "BANK (SAFE):  %d SCRAP" % UpgradeManager.hub_credits
	_hand_label.text   = "ON HAND:      %d SCRAP" % UpgradeManager.wallet_credits
	_amount_label.text = "%d" % _transfer_amount