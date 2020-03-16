--control.lua

require("mod-gui")
local channels = require("control.channels")

local function init_player(player)
    if not global.tacticalConstructionToggleState then
        global.tacticalConstructionToggleState = {}
    end
    if global.tacticalConstructionToggleState[player.index] == nil then
        global.tacticalConstructionToggleState[player.index] = false
    end
	build_gui(player)
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

local function on_gui_click(event)
    if event.element.name == "tacticalConstructionToggleButton" then
        if not global.tacticalConstructionToggleState[event.player_index] then
            global.tacticalConstructionToggleState[event.player_index] = true
        else
            global.tacticalConstructionToggleState[event.player_index] = false
        end
        update_guis()
	end
end

function build_gui(player)
    local parent = mod_gui.get_frame_flow(player)
    if not parent.tacticalConstructionToggleButton then
        parent.add({
            type = "sprite-button",
            name = "tacticalConstructionToggleButton", 
            style = "tactical-construction-sprite-style", 
            sprite = "tactical-construction-button-disabled"}
        )
    end
end
	
function update_guis()
	for i,_ in pairs(game.players) do
		local player = game.players[i]
        build_gui(player)
        local parent = mod_gui.get_frame_flow(player)
        if not global.tacticalConstructionToggleState[player.index] then
            parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-disabled"
        else
            parent.tacticalConstructionToggleButton.sprite = "tactical-construction-button-enabled"
        end
	end
end

script.on_init(on_init)
script.on_event(defines.events.on_player_created, on_player_created_or_joined )
script.on_event(defines.events.on_player_joined_game, on_player_created_or_joined )
script.on_event(defines.events.on_gui_click, on_gui_click )
