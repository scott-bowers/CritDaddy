-- CritDaddy.lua
-- Import necessary libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

local CritDaddy = AceAddon:NewAddon("CritDaddy", "AceConsole-3.0", "AceEvent-3.0")

-- Define the sounds directory and list of sound files
local SOUND_DIR = "Interface\\AddOns\\CritDaddy\\sounds"
local soundFiles = {
    "kaiwow.wav",
    "oohwhee.wav",
    "potofgreed.mp3",
    "theefiecook.mp3",
    "tioccawow.wav",
    "tioccacrit.wav",
    -- Add more sound files as needed
}

-- Initialization function, called when the addon is loaded
function CritDaddy:OnInitialize()
    -- Create database
    self.db = AceDB:New("CritDaddyDB", self:GetDefaultDB(), true)

    -- Register slash commands for the addon
    self:RegisterChatCommand("critdaddy", "SlashCommand")
    self:RegisterChatCommand("cd", "SlashCommand")

    -- Register options table without embedding
    AceConfig:RegisterOptionsTable("CritDaddy", self:GetOptions())
    AceConfigDialog:AddToBlizOptions("CritDaddy", "CritDaddy")

    --Enable the addon and register necessary events
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Function to define addon options using AceConfig
function CritDaddy:GetOptions()
    local options = {
        name = "CritDaddy",
        handler = CritDaddy,
        type = "group",
        args = {
            playTestSound = {
                type = "execute",
                name = "Play Test Sound",
                desc = "Play a test sound from the selected directory",
                func = function() self:PlaySelectedSound() end,
            },
            debug = {
                type = "toggle",
                name = "Debug Mode",
                desc = "Enable debug messages",
                get = function() return self.db.profile.debug end,
                set = function(_, value) self.db.profile.debug = value end,
                width = "full",
            },
            useRandomSound = {
                type = "toggle",
                name = "Use Random Sound",
                desc = "Toggle between using a random sound or a specific sound",
                get = function() return self.db.profile.useRandomSound end,
                set = function(_, value) self.db.profile.useRandomSound = value end,
            },
            soundSelection = {
                type = "select",
                name = "Selected Sound",
                desc = "Select the sound to play on a critical hit",
                get = function()
                    local selectedSound = self.db.profile.selectedSound
                    for index, soundFile in ipairs(soundFiles) do
                        if soundFile == selectedSound then
                            return index
                        end
                    end
                end,
                set = function(_, index)
                    self.db.profile.selectedSound = soundFiles[index]
                    self:PrintDebug("Selected sound set to: " .. soundFiles[index])
                end,
                values = self:GetSoundFileOptions(),
                style = "dropdown", 
            },
        },
    }
    return options
end

-- Function to get the options for the sound file dropdown menu
function CritDaddy:GetSoundFileOptions()
    local options = {}
    for index, soundFile in ipairs(soundFiles) do
        options[index] = soundFile
    end
    return options
end

-- Slash command handler
function CritDaddy:SlashCommand(input)
    if input == "" then
        -- Open the options menu
        InterfaceOptionsFrame_OpenToCategory("CritDaddy")
        InterfaceOptionsFrame_OpenToCategory("CritDaddy") -- Call twice to ensure it is fully opened
    else
        -- Handle other slash commands if needed
    end
end


-- Function to get default database settings
function CritDaddy:GetDefaultDB()
    return {
        profile = {
            debug = false,
            selectedSound = soundFiles[1], -- Default to the first sound file
            useRandomSound = false, -- Default to using the specific sound
        },
    }
end


-- Function to play the selected sound from the dropdown menu
function CritDaddy:PlaySelectedSound()
    local selectedSound = self.db.profile.selectedSound
    if selectedSound and selectedSound ~= "" then
        local soundPath = SOUND_DIR .. "\\" .. selectedSound
        PlaySoundFile(soundPath, "Master")
    else
        self:Print("No specific sound selected.")
    end
end



-- Function to play a random sound from the selected sound directory
function CritDaddy:PlayRandomSound()
    -- Check if sound files are available
    if #soundFiles > 0 then
        -- Select a random sound file
        local randomIndex = math.random(1, #soundFiles)
        local randomSound = soundFiles[randomIndex]

        -- Play the selected sound
        PlaySoundFile(SOUND_DIR .. "\\" .. randomSound, "Master")
    else
        self:PrintDebug("No sound files found in the selected directory.")
    end
end

-- Function to print debug messages to the chat window
function CritDaddy:PrintDebug(message)
    if self.db and self.db.profile.debug then
        self:Print("|cFF33FF99[Debug]|r " .. message)
    end
end

-- swing_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- spell_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- spell_heal:   timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overhealing, absorbed, critical

function CritDaddy:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, sourceGUID, sourceName, _, _, _, _, _, _, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22 = CombatLogGetCurrentEventInfo()

    if sourceGUID ~= UnitGUID("player") then
        return
    end

--    print("CLEU: " .. eventType .. " " .. sourceGUID .. " " .. sourceName .. " " .. arg12)
    if eventType == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Swing Damage: " .. amount)
            if self.db.profile.useRandomSound then
                self:PlayRandomSound()
            else
                self:PlaySelectedSound()
            end
        end
    elseif eventType == "SPELL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21
        if critical then
            self:PrintDebug("Critical Spell/Range Damage: " .. spellName .. " for " .. amount)
            if self.db.profile.useRandomSound then
                self:PlayRandomSound()
            else
                self:PlaySelectedSound()
            end
        end
    elseif eventType == "SPELL_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Heal: " .. spellName .. " for " .. amount)
            if self.db.profile.useRandomSound then
                self:PlayRandomSound()
            else
                self:PlaySelectedSound()
            end
        end
    end
end
