local force_manager = {}

force_manager.FORCE_REGEX = "(.+)%.tactical%.construction%.(%d+)"

function force_manager.is_force_ours(force)
    return string.match(force.name, force_manager.FORCE_REGEX) ~= nil
end

function force_manager.parse_force_name(force_name)
    local base_name, player_id = string.match(force_name, force_manager.FORCE_REGEX)
    if base_name then
        return base_name, tonumber(player_id)
    else
        return force_name
    end
end

function force_manager.create_force_name(base_force_name, player_id)
    if not player_id or player_id == 0 then
		return base_force_name
	else
        return base_force_name .. ".tactical.construction." .. player_id
    end
end

function force_manager.fetch_player_force_from_base(base_force, player_id)
    if not player_id or player_id == 0 then
		return nil
	else
        local player_force_name = force_manager.create_force_name(base_force.name, player_id)
        return game.forces[player_force_name]
    end
end

function force_manager.create_for_player(player)
    local base_force = player.force
    local player_id = player.index
	local player_force_name = force_manager.create_force_name(base_force.name, player_id)
    if not game.forces[player_force_name] then
        local player_force = game.create_force(player_force_name)
        player_force.set_friend(base_force, true)
        player_force.set_cease_fire(base_force, true)
        base_force.set_friend(player_force, true)
        base_force.set_cease_fire(player_force, true)
        player_force.share_chart = true
        base_force.share_chart = true
        player_force.cancel_charting()
        force_manager.sync_all_tech_to_force(base_force, player_force)
    end
    return game.forces[player_force_name]
end

function force_manager.destroy_for_player(player)
    local base_name, player_id = force_manager.parse_force_name(player.force.name)
    if player_id ~= nil then
        local base_force = game.forces[base_name]
        local player_force = player.force
        game.merge_forces(player_force, base_force)
    end
end

function force_manager.sync_all_tech_to_force(base_force, player_force)
    for name, tech in pairs(base_force.technologies) do
        player_force.technologies[name].researched = tech.researched;
    end
end

function force_manager.sync_single_tech_to_all_forces(technology)
    for _, force in pairs(game.forces) do
        if force_manager.is_force_ours(force) then
            force.technologies[technology.name].researched = technology.researched
        end
    end
end

function force_manager.restore_entity_base_force(entity)
	local base_name, player_specific_id = force_manager.parse_force_name(entity.force.name)
    if player_specific_id ~= nil then
        local base_force = game.forces[base_name]
        entity.force = base_force
    end
end

function force_manager.set_entity_player_force(entity, player_id)
    local player_force_name = create_force_name(entity.force.name, player_id)
    local player_force = game.forces[player_force_name]
    if player_force ~= nil then
        entity.force = player_force
    end
end

function force_manager.register_events()
    script.on_event(defines.events.on_research_finished,
        function(event)
            force_manager.sync_single_tech_to_all_forces(event.research)
        end
    )
end

return force_manager
