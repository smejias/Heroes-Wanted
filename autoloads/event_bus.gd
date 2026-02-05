extends Node

# Time
signal day_started(day: int)
signal hour_changed(hour: float)
signal time_scale_changed(scale: float)

# Resources
signal resources_changed(resource_type: int, amount: int)
signal resource_depleted(resource_type: int)

# Construction
signal build_mode_entered
signal build_mode_exited
signal district_selected(district_data: Resource)
signal construction_started(tile: Node3D, district_data: Resource)
signal construction_completed(tile: Node3D, district_data: Resource)

# Districts
signal district_disabled(district: Node3D)
signal district_damaged(district: Node3D)
signal district_repaired(district: Node3D)
signal district_paused(tile: Node3D)
signal district_resumed(tile: Node3D)

# Quests
signal quest_spawned(quest: Quest)
signal quest_assigned(quest: Quest, party: Party)
signal quest_resolved(quest: Quest, success: bool)
signal quest_expired(quest: Quest)
signal quest_selected_for_assignment(quest: Quest)

# Parties
signal party_arrived(party: Party)
signal party_departed(party: Party)
signal party_leaving_soon(party: Party)
signal party_hired(party: Party)
signal party_available(party: Party)
signal party_spawned(party: Party)
signal show_party_selection(quest: Quest)
signal emissary_sent
signal emissary_arrived

# Notifications
signal notification_requested(message: String, type: int)

# Population
signal population_changed(current: int, max_pop: int)
signal citizens_arrived(amount: int)
signal citizens_left(amount: int, reason: String)
signal max_population_changed(new_max: int)
signal game_over

#Appeal
signal appeal_changed(total: int, breakdown: Dictionary)
