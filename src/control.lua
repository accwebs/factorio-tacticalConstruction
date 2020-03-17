--control.lua

local channels = require("control.channels")
local gui = require("control.gui")

local function init_player(player)
    if not global.tacticalConstructionToggleState then
        global.tacticalConstructionToggleState = {}
    end
    if global.tacticalConstructionToggleState[player.index] == nil then
        global.tacticalConstructionToggleState[player.index] = {
            toggled = false,
            allocatedForce = -1
        }
    end
	gui.build_for_player(player)
end

local function init_players()
	for _, player in pairs(game.players) do
		init_player(player)
	end
end

local function on_init() 
	init_players()
end

local function on_player_created_or_joined(event)
	init_player(game.players[event.player_index])
end

script.on_init(on_init)
script.on_event(defines.events.on_player_created, on_player_created_or_joined )
script.on_event(defines.events.on_player_joined_game, on_player_created_or_joined )
gui.register_events()
