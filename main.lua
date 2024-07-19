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
    -- Set the master volume to the next preset value.  Return the new master
    -- volume value as a number in the range, '[0, 100]'.

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

            volume = volumePresets[i]
            setVolume(volume)
            return volume
        end
    end

    -- The current volume doesn't match any preset.  Set it to the first
    -- preset.

    volume = volumePresets[1]
    setVolume(volume)
    return volume
end

local initialVolume = getVolume()
local dataObject = ldb:NewDataObject('VolumeCycle',
                                     { ['type'] = 'data source',
                                       ['text'] = initialVolume .. '%',
                                       ['value'] = tostring(initialVolume),
                                       ['suffix'] = '%',
                                       ['label'] = 'Volume' })

dataObject.OnClick = function(self, button)
    if button == 'LeftButton' then
        local newVolume = cycleVolume()
        dataObject.value = tostring(newVolume)
        dataObject.text = newVolume .. '%'
    end
end
