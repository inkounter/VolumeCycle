local thisAddonName, namespace = ...

local presetDefaults = { 8, 15, 30, 80 }

local handleEvent = function(_, event, ...)
    if event == 'ADDON_LOADED' then
        local addon = ...
        if addon == thisAddonName and _G['VolumeCyclePresets'] == nil then
            _G['VolumeCyclePresets'] = presetDefaults
        end
    end
end

local Options = {
    ['setPresets'] = function(info, value)
        local volumePresets = {}
        for match in string.gmatch(value, '%d+') do
            table.insert(volumePresets, tonumber(match))
        end
        _G['VolumeCyclePresets'] = volumePresets
    end,

    ['getPresets'] = function(info)
        return table.concat(_G['VolumeCyclePresets'], ' ')
    end,

    ['defaultPresets'] = function()
        _G['VolumeCyclePresets'] = presetDefaults
    end,

    ['register'] = function(self)
        local ac = LibStub("AceConfig-3.0")
        local optionsTable = {
            ['name'] = thisAddonName,
            ['type'] = 'group',
            ['args'] = {
                ['presets'] = {
                    ['type'] = 'input',
                    ['order'] = 0,
                    ['name'] = 'Volume Presets',
                    ['desc'] = 'Space-delimited volume presets, as percentages.',
                    ['set'] = self.setPresets,
                    ['get'] = self.getPresets,
                    ['pattern'] = '[0-9 ,]',
                    ['usage'] = '8 15 30 80 100',
                },

                ['resetDefault'] = {
                    ['type'] = 'execute',
                    ['order'] = 1,
                    ['name'] = 'Reset to Default',
                    ['func'] = self.defaultPresets,
                }
            },
        }
        ac:RegisterOptionsTable(thisAddonName, optionsTable, nil)

        local acd = LibStub("AceConfigDialog-3.0")
        return acd:AddToBlizOptions(thisAddonName)
    end,
}

local optionsFrame, optionsCategoryId = Options:register()
namespace.optionsCategoryId = optionsCategoryId

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript('OnEvent', handleEvent)
