local thisAddonName, namespace = ...

local ldb = LibStub:GetLibrary('LibDataBroker-1.1')

local getVolume = function()
    -- Return the current master volume as a number in the range, '[0, 100]',
    -- rounded to the nearest integer.

    local cvar = GetCVar('Sound_MasterVolume')
    return math.floor(cvar * 100 + 0.5)
end

local setVolume = function(value)
    -- Set the master volume to the specified 'value', where 'value' is a
    -- number in the range, '[0, 100]'.

    SetCVar('Sound_MasterVolume', math.min(math.max(value, 0), 100) / 100)
end

local cycleVolume = function()
    -- Set the master volume to the next preset value.

    -- Since the set of presets should be small, linear iteration is fast
    -- enough, and we don't need binary search.

    local volumePresets = _G['VolumeCyclePresets']
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

local isMuted = function()
    -- Return 'true' if all sound is disabled.  Otherwise, return 'true'.

    return GetCVar('Sound_EnableAllSound') == '0'
end

local toggleMute = function()
    -- If all sound is disabled, enable it.  Otherwise, disable it.

    SetCVar('Sound_EnableAllSound', 1 and isMuted() or 0)
end

local handleEvent = function(_, event, ...)
    if event == 'CVAR_UPDATE' then
        local dataObject = namespace.dataObject

        -- Note that restarting the sound system fires 'CVAR_UPDATE's with some
        -- incorrect values, so we refetch the CVar rather than taking the
        -- value directly from the event.

        local cvar, _ = ...
        if cvar == 'Sound_MasterVolume' or cvar == 'Sound_EnableAllSound' then
            if cvar == 'Sound_MasterVolume' then
                dataObject.value = tostring(getVolume())
            end

            local colorSequence = ''
            if isMuted() then
                colorSequence = '|cnRED_FONT_COLOR:'
            end

            dataObject.text = colorSequence .. dataObject.value .. dataObject.suffix
        end
    end
end

local DataObject = {
    -- This is used as the initial value for the data object.

    ['type'] = 'data source',

    ['suffix'] = '%',

    ['label'] = 'Volume',

    ['icon'] = 'interface/common/voicechat-speaker.blp',

    ['OnClick'] = function(frame, mouseButton)
        if mouseButton == 'LeftButton' then
            cycleVolume()
        elseif mouseButton == 'MiddleButton' then
            Sound_GameSystem_RestartSoundSystem()
        elseif mouseButton == 'RightButton' then
            if IsShiftKeyDown() then
                Settings.OpenToCategory(namespace.optionsCategoryId)
            else
                toggleMute()
            end
        end
    end,

    ['OnTooltipShow'] = function(frame)
        frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Left Click:|r cycle through volume presets")
        frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Middle Click:|r reload default sound inputs/outputs")
        frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Right Click:|r toggle mute")
        frame:AddLine("|cnLIGHTBLUE_FONT_COLOR:Shift + Right Click:|r open options")
    end,
}

local initialVolume = getVolume()
namespace.dataObject = ldb:NewDataObject('VolumeCycle', DataObject)

local dummyFrame = CreateFrame("Frame")
dummyFrame:RegisterEvent('CVAR_UPDATE')
dummyFrame:SetScript('OnEvent', handleEvent)

-- Set an initial value for the data object.

handleEvent(nil, 'CVAR_UPDATE', 'Sound_MasterVolume')
