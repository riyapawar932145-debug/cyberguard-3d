class_name PaymentPrompt
extends InteractableObject3D
## A floating UPI/OTP kiosk screen. Interaction now happens entirely inside
## IncomingRequestPopup's live countdown card - this object only renders the in-world
## consequence once a decision (or a timeout) has been made.

const DEBIT_AMOUNT: String = "Rs 4,999"

@onready var prompt_label: Label3D = $PromptLabel
@onready var card_mesh: MeshInstance3D = $CardMesh
@onready var stamp_label: Label3D = $StampLabel

var _material: StandardMaterial3D


func _ready() -> void:
	stamp_label.visible = false
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.95, 0.78, 0.35)
	card_mesh.set_surface_override_material(0, _material)


func _configure(scenario: Dictionary) -> void:
	prompt_label.text = str(scenario.get("title", ""))


## Intentionally empty: UpiOtpKioskRoom opens IncomingRequestPopup directly instead of the
## generic ActionPopup - there is no fixed button list, the countdown card handles everything.
func get_action_options() -> Array:
	return []


func play_consequence(was_correct: bool, action: String) -> void:
	stamp_label.visible = true

	match action:
		"approved":
			if was_correct:
				stamp_label.text = "PAYMENT SENT"
				_material.albedo_color = Color(0.3, 0.75, 0.4)
			else:
				stamp_label.text = "MONEY DEBITED -%s" % DEBIT_AMOUNT
				_material.albedo_color = Color(0.85, 0.2, 0.2)
		"declined":
			stamp_label.text = "REQUEST BLOCKED"
			_material.albedo_color = Color(0.3, 0.75, 0.4) if was_correct else Color(0.55, 0.55, 0.6)
		"shared_otp":
			stamp_label.text = "OTP STOLEN"
			_material.albedo_color = Color(0.85, 0.2, 0.2)
		_:
			stamp_label.text = "NO ACTION"
			_material.albedo_color = Color(0.6, 0.6, 0.65)

	stamp_label.modulate = Color(0.3, 0.85, 0.45) if was_correct else Color(0.9, 0.25, 0.25)
