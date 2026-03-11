## RetrieveItemObjective — objective requiring the player to collect an item.
##
## Completes when [method report_retrieval] is called with the matching item ID.
class_name RetrieveItemObjective
extends MissionObjective

## Unique identifier for the target item.
var item_id: String = ""


func _init(desc: String = "Retrieve the item", itm_id: String = "") -> void:
	super._init(desc, 1)
	item_id = itm_id


## Report an item retrieval. Completes if the ID matches.
func report_retrieval(retrieved_item_id: String) -> void:
	if is_completed:
		return

	if retrieved_item_id == item_id:
		complete()
