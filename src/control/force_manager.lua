local force_manager = {}

force_manager.FORCE_REGEX = "(.+)%.tactical%.construction"

function force_manager.is_force_alternative(force)
    return string.match(force.name, force_manager.FORCE_REGEX) ~= nil
end

function force_manager.parse_force_name(force_name)
    local base_name = string.match(force_name, force_manager.FORCE_REGEX)
    if base_name then
        return base_name, true
    else
        return force_name, false
    end
end

function force_manager.create_alternative_force_name(base_force_name)
    return base_force_name .. ".tactical.construction"
end

function force_manager.fetch_base_force(player)
    local base_force_name, is_force_alternative = force_manager.parse_force_name(player.force.name)
    return game.forces[base_force_name]
end

function force_manager.fetch_alternative_force(player)
    if force_manager.is_force_alternative(player.force) == false then
        local alternative_force_name = force_manager.create_alternative_force_name(player.force.name, player.index)
        return game.forces[alternative_force_name]
    else
        return player.force
    end
end

function force_manager.init_player(player)
    local base_force_name, is_force_alternative = force_manager.parse_force_name(player.force.name)
	local alternative_force_name = force_manager.create_alternative_force_name(base_force_name)
    if not game.forces[alternative_force_name] then
        local base_force = game.forces[base_force_name]
        local alternative_force = game.create_force(alternative_force_name)
        alternative_force.set_friend(base_force, true)
        alternative_force.set_cease_fire(base_force, true)
        base_force.set_friend(alternative_force, true)
        base_force.set_cease_fire(alternative_force, true)
        alternative_force.share_chart = true
        base_force.share_chart = true
        force_manager.sync_all_tech_to_force(base_force, alternative_force)
    end
end

function force_manager.deinit_player(deinit_player)
    local deinit_player_base_force_name, is_force_alternative1 = force_manager.parse_force_name(deinit_player.force.name)
    local deinit_player_alterative_force_name = force_manager.create_alternative_force_name(deinit_player_base_force_name)
    
    local delete_force = true
    for _, this_player in pairs(game.players) do
        if this_player ~= deinit_player then
            if this_player.connected == true then
                local this_player_base_force_name, is_force_alternative = force_manager.parse_force_name(this_player.force.name)
                if deinit_player_base_force_name == this_player_base_force_name then
                    delete_force = false
                    break
                end
            end
        end
    end

    if delete_force == true then
        local base_force = game.forces[deinit_player_base_force_name]
        local alternative_force = game.forces[deinit_player_alterative_force_name]
        game.merge_forces(alternative_force, base_force)
    end
end

function force_manager.switch_player_to_alternative_force(player)
    player.force = force_manager.fetch_alternative_force(player)
end

function force_manager.restore_player_original_force(player)
    local base_name, player_id = force_manager.parse_force_name(player.force.name)
    if player_id ~= nil then
        local base_force = game.forces[base_name]
        player.force = base_force
    end
end

function force_manager.sync_all_tech_to_force(base_force, player_force)
    for name, tech in pairs(base_force.technologies) do
        player_force.technologies[name].researched = tech.researched;
    end
end

function force_manager.sync_single_tech_to_all_forces(technology)
    for _, force in pairs(game.forces) do
        if force_manager.is_force_alternative(force) then
            force.technologies[technology.name].researched = technology.researched
        end
    end
end

function force_manager.restore_entity_base_force(entity)
	local base_force_name, is_force_alternative = force_manager.parse_force_name(entity.force.name)
    if is_force_alternative == true then
        local base_force = game.forces[base_force_name]
        if base_force ~= nil then
            entity.force = base_force
        end
    end
end

function force_manager.set_entity_alternative_force(entity)
    local alternative_force_name = force_manager.create_alternative_force_name(entity.force.name)
    local alternative_force = game.forces[alternative_force_name]
    if alternative_force ~= nil then
        entity.force = alternative_force
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
