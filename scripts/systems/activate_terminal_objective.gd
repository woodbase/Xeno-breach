## ActivateTerminalObjective — objective requiring the player to activate a terminal.
##
## Completes when [method report_activation] is called with the matching terminal ID.
class_name ActivateTerminalObjective
extends MissionObjective

## Unique identifier for the target terminal.
var terminal_id: String = ""


func _init(desc: String = "Activate the terminal", term_id: String = "") -> void:
	super._init(desc, 1)
	terminal_id = term_id


## Report a terminal activation. Completes if the ID matches.
func report_activation(activated_terminal_id: String) -> void:
	if is_completed:
		return

	if activated_terminal_id == terminal_id:
		complete()
