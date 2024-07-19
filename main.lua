local thisAddonName, namespace = ...

local ldb = LibStub:GetLibrary('LibDataBroker-1.1')

namespace.volumePresets = { 0, 8, 15, 30, 80 }
local volumePresets = namespace.volumePresets

local getVolume = function()
    -- Return the current master volume as a number in the range, '[0, 100]',
    -- rounded to the nearest integer.

    local cvar = GetCVar('Sound_MasterVolume')
    return math.floor(cvar * 100 + 0.5)
end

local setVolume = function(value)
    -- Set the master volume to the specified 'value', where 'value' is a
    -- number in the range, '[0, 100]'.

    SetCVar('Sound_MasterVolume', value / 100)
end

local cycleVolume = function()
    -- Set the master volume to the next preset value.

    -- Since the set of presets should be small, linear iteration is fast
    -- enough, and we don't need binary search.

    local volume = getVolume()
    for i, preset in ipairs(volumePresets) do
        if volume == preset then
            if i == #volumePresets then
                -- Wrap around to the beginning.

                i = 1
            else
                i = i + 1
            end

            setVolume(volumePresets[i])
            return
        end
    end

    -- The current volume doesn't match any preset.  Set it to the first
    -- preset.

    setVolume(volumePresets[1])
end

local initialVolume = getVolume()
local dataObject = ldb:NewDataObject('VolumeCycle',
                                     { ['type'] = 'data source',
                                       ['text'] = initialVolume .. '%',
                                       ['value'] = tostring(initialVolume),
                                       ['suffix'] = '%',
                                       ['label'] = 'Volume' })

dataObject.OnClick = function(frame, mouseButton)
    if mouseButton == 'LeftButton' then
        cycleVolume()
    elseif mouseButton == 'MiddleButton' then
        Sound_GameSystem_RestartSoundSystem()
    end
end

dataObject.OnTooltipShow = function(frame)
    frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Left Click:|r cycle through volume presets")
    frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Middle Click:|r reload default sound inputs/outputs")
end

local dummyFrame = CreateFrame("Frame")
local handleEvent = function(self, event, ...)
    if event == 'CVAR_UPDATE' then
        -- Note that restarting the sound system fires 'CVAR_UPDATE's with some
        -- incorrect values, so we refetch the CVar rather than taking the
        -- value directly from the event.

        local cvar, _ = ...
        if cvar == 'Sound_MasterVolume' then
            dataObject.value = tostring(getVolume())
            dataObject.text = dataObject.value .. dataObject.suffix
        end
    end
end

dummyFrame:RegisterEvent('CVAR_UPDATE')
dummyFrame:SetScript('OnEvent', handleEvent)
