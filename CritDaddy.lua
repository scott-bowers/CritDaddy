-- CritDaddy.lua
-- WoW Addon to play sounds on critical hits.
-- Dependencies: AceAddon-3.0, AceConfig-3.0, AceConfigDialog-3.0, AceDB-3.0

-- Import necessary libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Main addon declaration
local CritDaddy = AceAddon:NewAddon("CritDaddy", "AceConsole-3.0", "AceEvent-3.0")

-- Encapsulating sound directory and files within the addon table
CritDaddy.SOUND_DIR = "Interface\\AddOns\\CritDaddy\\sounds"
CritDaddy.soundFiles = {
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
    -- Create database with default settings
    self.db = AceDB:New("CritDaddyDB", self:GetDefaultDB(), true)

    -- Registering slash commands
    self:RegisterChatCommand("critdaddy", "SlashCommand")
    self:RegisterChatCommand("cd", "SlashCommand")

    -- Setting up configuration options
    AceConfig:RegisterOptionsTable("CritDaddy", self:GetOptions())
    AceConfigDialog:AddToBlizOptions("CritDaddy", "CritDaddy")

    -- Registering event handler
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
                    for index, soundFile in ipairs(self.soundFiles) do
                        if soundFile == selectedSound then
                            return index
                        end
                    end
                end,
                set = function(_, index)
                    self.db.profile.selectedSound = self.soundFiles[index]
                    self:PrintDebug("Selected sound set to: " .. self.soundFiles[index])
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
    for index, soundFile in ipairs(self.soundFiles) do
        options[index] = soundFile
    end
    return options
end

-- Slash command handler
function CritDaddy:SlashCommand(input)
    if input == "" then
        -- Open the options menu
        InterfaceOptionsFrame_OpenToCategory("CritDaddy")
        InterfaceOptionsFrame_OpenToCategory("CritDaddy") -- Twice to ensure it opens
    else
        -- Future implementation for additional commands
    end
end

-- Default database settings
function CritDaddy:GetDefaultDB()
    return {
        profile = {
            debug = false,
            selectedSound = self.soundFiles[1], -- First sound as default
            useRandomSound = false, -- Default to a specific sound
        },
    }
end

-- Play the selected sound
function CritDaddy:PlaySelectedSound()
    local selectedSound = self.db.profile.selectedSound
    if selectedSound and selectedSound ~= "" then
        local soundPath = self.SOUND_DIR .. "\\" .. selectedSound
        PlaySoundFile(soundPath, "Master")
    else
        self:Print("No specific sound selected.")
    end
end

-- Play a random sound
function CritDaddy:PlayRandomSound()
    if #self.soundFiles > 0 then
        local randomIndex = math.random(1, #self.soundFiles)
        local randomSound = self.soundFiles[randomIndex]
        PlaySoundFile(self.SOUND_DIR .. "\\" .. randomSound, "Master")
    else
        self:PrintDebug("No sound files found.")
    end
end

-- Function to play sound based on user settings
function CritDaddy:PlaySoundBasedOnSetting()
    if self.db.profile.useRandomSound then
        self:PlayRandomSound()
    else
        self:PlaySelectedSound()
    end
end

-- Debug message printing
function CritDaddy:PrintDebug(message)
    if self.db and self.db.profile.debug then
        self:Print("|cFF33FF99[Debug]|r " .. message)
    end
end

-- Combat event handler
function CritDaddy:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, sourceGUID, sourceName, _, _, _, _, _, _, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22 = CombatLogGetCurrentEventInfo()

    if sourceGUID ~= UnitGUID("player") then
        return
    end

    if eventType == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Swing Damage: " .. amount)
            CritDaddy:PlaySoundBasedOnSetting()
        end
    elseif eventType == "SPELL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21
        if critical then
            self:PrintDebug("Critical Spell/Range Damage: " .. spellName .. " for " .. amount)
            CritDaddy:PlaySoundBasedOnSetting()
        end
    elseif eventType == "SPELL_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Heal: " .. spellName .. " for " .. amount)
            CritDaddy:PlaySoundBasedOnSetting()
        end
    end
end

-- swing_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- spell_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- spell_heal:   timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overhealing, absorbed, critical