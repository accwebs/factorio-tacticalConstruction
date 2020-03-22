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

function force_manager.is_logistic_network_player_owned(player, logistic_network)
    local good_network = 0
    for _, cell in pairs(logistic_network.cells) do
        if cell.valid == true then
            if cell.owner == player.character then
                good_network = good_network + 1
            else
                good_network = 0
                break
            end
        end
    end
    if good_network > 0 then
        return true
    else
        return false
    end
end

function force_manager.switch_player_robots_force(player, new_force)
    local switched_robots = {}

    if player.character ~= nil then
        local player_logistic_points = player.character.get_logistic_point()
        if type(player_logistic_points) ~= "table" then
            local temp = player_logistic_points
            player_logistic_points = {}
            player_logistic_points[1] = temp
        end

        for _, point in pairs(player_logistic_points) do
            if point.valid == true then
                if point.logistic_network.valid == true then
                    if force_manager.is_logistic_network_player_owned(player, point.logistic_network) then
                        for _, robot in pairs(point.logistic_network.robots) do
                            switched_robots[robot] = true
                            robot.force = new_force
                        end
                    end
                end
            end
        end
    end

    return switched_robots
end

function force_manager.reattach_switched_robots_to_network(switched_robots, player)
    if player.character ~= nil then
        local player_logistic_points = player.character.get_logistic_point()
        if type(player_logistic_points) ~= "table" then
            local temp = player_logistic_points
            player_logistic_points = {}
            player_logistic_points[1] = temp
        end

        local correct_player_network = nil
        for _, point in pairs(player_logistic_points) do
            if point.valid == true then
                if point.logistic_network.valid == true then
                    if force_manager.is_logistic_network_player_owned(player, point.logistic_network) then
                        correct_player_network = point.logistic_network
                        break
                    end
                end
            end
        end

        if correct_player_network ~= nil then
            for robot, _ in pairs(switched_robots) do
                robot.logistic_network = correct_player_network
            end
        end
    end
end

function force_manager.switch_player_to_alternative_force(player)
    local alternative_force = force_manager.fetch_alternative_force(player)
    local switched_robots = force_manager.switch_player_robots_force(player, alternative_force)
    player.force = alternative_force
    force_manager.reattach_switched_robots_to_network(switched_robots, player)
end

function force_manager.restore_player_original_force(player)
    local base_name, player_id = force_manager.parse_force_name(player.force.name)
    if player_id ~= nil then
        local base_force = game.forces[base_name]
        local switched_robots = force_manager.switch_player_robots_force(player, base_force)
        player.force = base_force
        force_manager.reattach_switched_robots_to_network(switched_robots, player)
    end
end

function force_manager.sync_all_tech_to_force(base_force, alternative_force)
    for name, tech in pairs(base_force.technologies) do
        alternative_force.technologies[name].researched = tech.researched;
    end
    force_manager.sync_force_bonuses(base_force, alternative_force)
end

function force_manager.sync_single_tech_to_force(technology)
    local base_force, is_alternative = force_manager.parse_force_name(technology.force.name)
    if is_alternative == false then
        local alternative_force_name = force_manager.create_alternative_force_name(base_force.name)
        local alternative_force = game.forces[alternative_force_name]
        base_force.technologies[technology.name].researched = technology.researched
        force_manager.sync_force_bonuses(base_force, alternative_force)
    end
end

function force_manager.sync_force_bonuses(base_force, alternative_force)
    -- TODO: Figure out how to sync these??
    -- get_ammo_damage_modifier(ammo)
    -- set_ammo_damage_modifier(ammo, modifier)
    -- get_gun_speed_modifier(ammo)
    -- set_gun_speed_modifier(ammo, modifier)
    -- get_turret_attack_modifier(turret)
    -- set_turret_attack_modifier(turret, modifier)
    alternative_force.manual_mining_speed_modifier = base_force.manual_mining_speed_modifier
    alternative_force.manual_crafting_speed_modifier = base_force.manual_crafting_speed_modifier
    alternative_force.laboratory_speed_modifier = base_force.laboratory_speed_modifier
    alternative_force.laboratory_productivity_bonus = base_force.laboratory_productivity_bonus
    alternative_force.worker_robots_speed_modifier = base_force.worker_robots_speed_modifier
    alternative_force.worker_robots_battery_modifier = base_force.worker_robots_battery_modifier
    alternative_force.following_robots_lifetime_modifier = base_force.following_robots_lifetime_modifier
    alternative_force.character_running_speed_modifier = base_force.character_running_speed_modifier
    alternative_force.artillery_range_modifier = base_force.artillery_range_modifier
    alternative_force.inserter_stack_size_bonus = base_force.inserter_stack_size_bonus
    alternative_force.stack_inserter_capacity_bonus = base_force.stack_inserter_capacity_bonus
    alternative_force.character_build_distance_bonus = base_force.character_build_distance_bonus
    alternative_force.character_item_drop_distance_bonus = base_force.character_item_drop_distance_bonus
    alternative_force.character_reach_distance_bonus = base_force.character_reach_distance_bonus
    alternative_force.character_resource_reach_distance_bonus = base_force.character_resource_reach_distance_bonus
    alternative_force.character_item_pickup_distance_bonus = base_force.character_item_pickup_distance_bonus
    alternative_force.character_loot_pickup_distance_bonus = base_force.character_loot_pickup_distance_bonus
    alternative_force.character_inventory_slots_bonus = base_force.character_inventory_slots_bonus
    alternative_force.character_health_bonus = base_force.character_health_bonus
    alternative_force.mining_drill_productivity_bonus = base_force.mining_drill_productivity_bonus
    alternative_force.train_braking_force_bonus = base_force.train_braking_force_bonus
end

function force_manager.restore_entity_original_force(entity)
	local base_force_name, is_force_alternative = force_manager.parse_force_name(entity.force.name)
    if is_force_alternative == true then
        local base_force = game.forces[base_force_name]
        if base_force ~= nil then
            local re_deconstruct = entity.to_be_deconstructed()
            local re_upgrade = entity.to_be_upgraded()
            entity.force = base_force
            if re_deconstruct == true then
                entity.order_deconstruction(base_force, nil)
            end
            if re_upgrade == true and entity.prototype.next_upgrade ~= nil then
                entity.order_upgrade({
                    force=base_force,
                    target=entity.prototype.next_upgrade
                })
            end
        end
    end
end

function force_manager.set_entity_alternative_force(entity)
    local alternative_force_name = force_manager.create_alternative_force_name(entity.force.name)
    local alternative_force = game.forces[alternative_force_name]
    if alternative_force ~= nil then
        local re_deconstruct = entity.to_be_deconstructed()
        local re_upgrade = entity.to_be_upgraded()
        entity.force = alternative_force
        if re_deconstruct == true then
            entity.order_deconstruction(alternative_force, nil)
        end
        if re_upgrade == true and entity.prototype.next_upgrade ~= nil then
            entity.order_upgrade({
                force=alternative_force,
                target=entity.prototype.next_upgrade
            })
        end
    end
end

function force_manager.register_events()
    script.on_event(defines.events.on_research_finished,
        function(event)
            force_manager.sync_single_tech_to_force(event.research)
        end
    )
end

return force_manager
