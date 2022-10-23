local force_manager = {}

force_manager.FORCE_REGEX = "(.+)%.tactical%.construction"

function force_manager._is_force_alternative(force)
    return string.match(force.name, force_manager.FORCE_REGEX) ~= nil
end

function force_manager._parse_force_name(force_name)
    local base_name = string.match(force_name, force_manager.FORCE_REGEX)
    if base_name then
        return base_name, true
    else
        return force_name, false
    end
end

function force_manager._create_alternative_force_name(base_force_name)
    return base_force_name .. ".tactical.construction"
end

function force_manager.fetch_base_force(current_force)
    local base_force_name, is_force_alternative = force_manager._parse_force_name(current_force.name)
    return game.forces[base_force_name]
end

function force_manager.fetch_alternative_force(current_force)
    if force_manager._is_force_alternative(current_force) == false then
        local alternative_force_name = force_manager._create_alternative_force_name(current_force.name)

        -- if doesn't exist, create it now
        if not game.forces[alternative_force_name] then
            local base_force = game.forces[current_force.name]
            local alternative_force = game.create_force(alternative_force_name)
            alternative_force.set_friend(base_force, true)
            alternative_force.set_cease_fire(base_force, true)
            base_force.set_friend(alternative_force, true)
            base_force.set_cease_fire(alternative_force, true)
            alternative_force.share_chart = true
            base_force.share_chart = true
            force_manager._sync_all_tech_to_force(base_force, alternative_force)
            if global.luaforce_color_apis_present == true then
                alternative_force.custom_color = base_force.color
            end
        end

        return game.forces[alternative_force_name]
    else
        return current_force
    end
end

function force_manager._is_logistic_network_player_owned(player, logistic_network)
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

function force_manager._switch_player_robots_force(player, new_force)
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
                    if force_manager._is_logistic_network_player_owned(player, point.logistic_network) then
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

function force_manager._reattach_switched_robots_to_network(switched_robots, player)
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
                    if force_manager._is_logistic_network_player_owned(player, point.logistic_network) then
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

function force_manager._back_up_player_logistic_request_counts(player)
    local output = {}
    if player.character ~= nil then
        local character = player.character
        for i = 1,character.request_slot_count do
            local slot = character.get_request_slot(i)
            if slot then
                output[i] = slot.count
            end
        end
    end
    return output
end

function force_manager._restore_player_logistic_request_counts(player, req_counts)
    local output = {}
    if player.character ~= nil then
        local character = player.character
        for index, correct_count in pairs(req_counts) do
            local slot = character.get_request_slot(index)
            if slot then
                if slot.count ~= correct_count then
                    slot.count = correct_count
                    character.set_request_slot(slot, index)
                end
            end
        end
    end
end

function force_manager._sync_all_tech_to_force(base_force, alternative_force)
    for name, tech in pairs(base_force.technologies) do
        alternative_force.technologies[name].researched = tech.researched;
    end
    force_manager._sync_force_bonuses(base_force, alternative_force)
end

function force_manager._sync_single_tech_to_alternative_force(technology)
    local base_force_name, is_alternative = force_manager._parse_force_name(technology.force.name)
    if is_alternative == false then
        local base_force = game.forces[base_force_name]

        -- bypass creation of alternative force if it does not exist
        local alternative_force_name = force_manager._create_alternative_force_name(base_force_name)
        local alternative_force = game.forces[alternative_force_name]

        if alternative_force ~= nil then
            alternative_force.technologies[technology.name].researched = technology.researched
            if technology.level ~= nil then
                alternative_force.technologies[technology.name].level = technology.level
            end
            force_manager._sync_force_bonuses(base_force, alternative_force)
        end
    end
end

function force_manager._sync_force_bonuses(base_force, alternative_force)
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

function force_manager.switch_player_to_alternative_force(player)
    local alternative_force = force_manager.fetch_alternative_force(player.force)
    if player.force.name ~= alternative_force.name then
        -- ensure alternative force has character logistic request characteristics set to same value as main force
        alternative_force.character_logistic_requests = player.force.character_logistic_requests
        alternative_force.character_trash_slot_count = player.force.character_trash_slot_count

        local switched_robots = force_manager._switch_player_robots_force(player, alternative_force)
        local req_counts = force_manager._back_up_player_logistic_request_counts(player)
        player.force = alternative_force
        force_manager._restore_player_logistic_request_counts(player, req_counts)
        force_manager._reattach_switched_robots_to_network(switched_robots, player)
    end
end

function force_manager.restore_player_original_force(player)
    local base_force = force_manager.fetch_base_force(player.force)
    if player.force.name ~= base_force.name then
        local switched_robots = force_manager._switch_player_robots_force(player, base_force)
        local req_counts = force_manager._back_up_player_logistic_request_counts(player)
        player.force = base_force
        force_manager._restore_player_logistic_request_counts(player, req_counts)
        force_manager._reattach_switched_robots_to_network(switched_robots, player)
    end
end

function force_manager.garbage_collect(reset_regardless_of_player_status)
    for _, force in pairs(game.forces) do
        local base_name, is_alternative = force_manager._parse_force_name(force.name)
        if is_alternative == true then
            local alternative_force_name = force.name
            local base_force_name = base_name

            local delete_force = true
            for _, this_player in pairs(force.players) do
                if this_player.connected == true then
                    delete_force = false
                end
            end
            local base_force = game.forces[base_force_name]
            for _, this_player in pairs(base_force.players) do
                if this_player.connected == true then
                    delete_force = false
                end
            end
            if delete_force == true or reset_regardless_of_player_status == true then
                local alternative_force = game.forces[alternative_force_name]
                game.merge_forces(alternative_force, base_force)
            end
        else 
            if reset_regardless_of_player_status == true then
                force.custom_color = nil
            end
        end
    end
    if global.luaforce_color_apis_present == true and reset_regardless_of_player_status == false then
        for _, force in pairs(game.forces) do
            local base_name, is_alternative = force_manager._parse_force_name(force.name)
            if is_alternative == false then
                local alternative_force_name = force_manager._create_alternative_force_name(base_name)
                if not game.forces[alternative_force_name] then
                    force.custom_color = nil
                end
            end
        end
    end
end

-- pre: players must all be on their primary forces
function force_manager.read_and_lock_force_colors()
    if global.luaforce_color_apis_present == true then
        -- lock the color of all primary forces
        for _, force in pairs(game.forces) do
            local base_name, is_alternative = force_manager._parse_force_name(force.name)
            if is_alternative == false then
                force.custom_color = nil  -- set back to dynamic computation temporarily
                force.custom_color = force.color
            end
        end
        -- set the color of all 'alternative' forces to match the color of the primary force
        for _, force in pairs(game.forces) do
            local base_name, is_alternative = force_manager._parse_force_name(force.name)
            if is_alternative == true then
                local base_force = game.forces[base_name]
                force.custom_color = base_force.color
            end
        end
    end
end

function force_manager.notify_research_started(event)
    local research_force = event.research.force
    local base_force_name, is_force_alternative = force_manager._parse_force_name(research_force.name)

    if is_force_alternative then
        research_force.research_queue = nil
        for _, player in pairs(game.players) do
            if player.connected == true then
                player.print({"caution.advise-do-not-research-on-alt-force", player.name})
            end
        end
    end
end


function force_manager.notify_research_finished(event)
    force_manager._sync_single_tech_to_alternative_force(event.research)
end

return force_manager
