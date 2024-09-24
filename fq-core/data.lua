local ammo = util.copy(data.raw.ammo["shotgun-shell"])

ammo.name = "custom-attack-shotgun-shell"
ammo.ammo_type.action = {
    type = "direct",
    action_delivery = {
        type = "instant",
        source_effects = {type = "create-explosion", entity_name = "explosion-gunshot"},
        target_effects = {type = "script", effect_id = "custom-attack"}
    }
}

data:extend({ammo})




