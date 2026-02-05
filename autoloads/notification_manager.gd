extends Node

enum Type { INFO, WARNING, SUCCESS, DANGER }


func _ready() -> void:
	EventBus.party_arrived.connect(_on_party_arrived)
	EventBus.party_leaving_soon.connect(_on_party_leaving_soon)
	EventBus.party_departed.connect(_on_party_departed)
	EventBus.quest_spawned.connect(_on_quest_spawned)
	EventBus.quest_resolved.connect(_on_quest_resolved)
	EventBus.quest_expired.connect(_on_quest_expired)
	EventBus.district_paused.connect(_on_district_paused)
	EventBus.district_resumed.connect(_on_district_resumed)
	EventBus.citizens_arrived.connect(_on_citizens_arrived)
	EventBus.citizens_left.connect(_on_citizens_left)
	EventBus.game_over.connect(_on_game_over)
	EventBus.emissary_sent.connect(_on_emissary_sent)
	EventBus.emissary_arrived.connect(_on_emissary_arrived)


func _on_district_paused(tile: Tile) -> void:
	var name = tile.district_data.display_name if tile.district_data else "District"
	notify("%s paused: not enough resources" % name, Type.WARNING)


func _on_district_resumed(tile: Tile) -> void:
	var name = tile.district_data.display_name if tile.district_data else "District"
	notify("%s resumed production" % name, Type.INFO)


func _on_party_arrived(party: Party) -> void:
	notify("%s arrived in the city! (Level %d)" % [party.display_name, party.level], Type.INFO)


func _on_party_leaving_soon(party: Party) -> void:
	notify("%s is leaving soon!" % party.display_name, Type.WARNING)


func _on_party_departed(party: Party) -> void:
	notify("%s left the city." % party.display_name, Type.INFO)


func _on_quest_spawned(quest: Quest) -> void:
	notify("New quest: %s" % quest.data.display_name, Type.WARNING)


func _on_quest_resolved(quest: Quest, success: bool) -> void:
	if success:
		notify("Quest completed: %s" % quest.data.display_name, Type.SUCCESS)
	else:
		notify("Quest failed: %s" % quest.data.display_name, Type.DANGER)


func _on_quest_expired(quest: Quest) -> void:
	notify("Quest expired: %s" % quest.data.display_name, Type.DANGER)


func notify(message: String, type: Type = Type.INFO) -> void:
	EventBus.notification_requested.emit(message, type)
	print("[Notification] ", message)

func _on_citizens_arrived(amount: int) -> void:
	if amount == 1:
		notify("A new citizen arrived!", Type.SUCCESS)
	else:
		notify("%d new citizens arrived!" % amount, Type.SUCCESS)


func _on_citizens_left(amount: int, reason: String) -> void:
	var message: String
	if amount == 1:
		message = "A citizen left (%s)" % reason
	else:
		message = "%d citizens left (%s)" % [amount, reason]
	
	notify(message, Type.WARNING)


func _on_game_over() -> void:
	notify("GAME OVER - All citizens have left!", Type.DANGER)

func _on_emissary_sent() -> void:
	notify("Emissary dispatched to find heroes!", Type.INFO)


func _on_emissary_arrived() -> void:
	notify("Emissary returned with a party!", Type.SUCCESS)
