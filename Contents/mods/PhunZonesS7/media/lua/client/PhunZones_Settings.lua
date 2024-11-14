local PhunZones = PhunZones
local sandbox = SandboxVars.PhunZones

if ModOptions and ModOptions.getInstance then

    local function onModOptionsApply(optionValues)
        if optionValues and optionValues.settings.options.show_widget == true then
            -- Open any closed panels
            if sandbox.PhunZones_Widget then
                for i = 0, getOnlinePlayers():size() - 1 do
                    local p = getOnlinePlayers():get(i)
                    if p:isLocalPlayer() then
                        PhunZonesWidget.OnOpenPanel(p)
                    end
                end
            end
        else
            -- Close any open panels
            for i = 1, getOnlinePlayers():size() do
                local p = getOnlinePlayers():get(i - 1)
                if p:isLocalPlayer() then
                    PhunZonesWidget.OnOpenPanel(p):close()
                end
            end
        end
    end

    local function onModOptionsApplyInGame(optionValues)
        onModOptionsApply(optionValues)
    end
    local SETTINGS = {
        options_data = {
            show_widget = {
                name = "Show Widget",
                default = true,
                tooltip = 'Show the PhunZones widget on the screen',
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApplyInGame
            }
        }
    }
    local optionsInstance = ModOptions:getInstance(SETTINGS)
    ModOptions:loadFile()
    local showWidget = optionsInstance:getData("show_widget", true)
    function showWidget:onUpdate(newValue)
        showWidget:set(newValue)
        PhunZones.settings.show_widget = newValue
        for i = 0, getOnlinePlayers():size() - 1 do
            local p = getOnlinePlayers():get(i)
            if p:isLocalPlayer() then
                if newValue and sandbox.PhunZones_Widget then
                    PhunZonesWidget.OnOpenPanel(p)
                else
                    PhunZonesWidget.OnOpenPanel(p):close()
                end
            end
        end
    end

    Events.OnGameStart.Add(function()
        onModOptionsApplyInGame({
            settings = SETTINGS
        })
    end)
end
