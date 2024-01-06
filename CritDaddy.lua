-- CritDaddy.lua
-- WoW Addon to play sounds on critical hits, misses, or resists.
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

CritDaddy.positiveSoundFiles = {
    "kaiwow.wav",
    "oohwhee.wav",
    "potofgreed.mp3",
    "theefiecook.mp3",
    "tioccawow.wav",
    "tioccacrit.wav",
    -- Add more sound files as needed
}

CritDaddy.negativeSoundFiles = {
    "decilaff.ogg",
    "debbyaightdude.ogg",
    "debbywhaddyawanmetosaythen.ogg",
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
            debug = {
                type = "toggle",
                name = "Debug Mode",
                desc = "Enable debug messages",
                get = function() return self.db.profile.debug end,
                set = function(_, value) self.db.profile.debug = value end,
                width = "full",
                order = 1
            },
            critSoundOptions = {
                type = "group",
                name = "Critical Hit Options",
                inline = true,
                width = "full",
                args = {
                    useRandomCritSound = {
                        type = "toggle",
                        name = "Use Random CRIT Sound",
                        desc = "Toggle between using a random sound or a specific sound for CRITs",
                        get = function() return self.db.profile.useRandomCritSound end,
                        set = function(_, value) self.db.profile.useRandomCritSound = value end,
                        order = 29
                    },
                    critSoundSelection = {
                        type = "select",
                        name = "CRIT Sound Selection",
                        desc = "Select the sound to play on a Critical hit",
                        get = function()
                            local selectedCritSound = self.db.profile.selectedCritSound
                            for index, soundFile in ipairs(self.positiveSoundFiles) do
                                if soundFile == selectedCritSound then
                                    return index
                                end
                            end
                        end,
                        set = function(_, index)
                            self.db.profile.selectedCritSound = self.positiveSoundFiles[index]
                            self:PrintDebug("CRIT sound set to: " .. self.positiveSoundFiles[index])
                        end,
                        values = self.positiveSoundFiles,
                        style = "dropdown", 
                        order = 22
                    },
                    playCritTestSound = {
                        type = "execute",
                        name = "Play Test CRIT Sound",
                        desc = "Play a test sound for CRIT",
                        func = function() self:PlaySelectedCritSound() end,
                        order = 23
                    },

                },
            },
            missSoundOptions = {
                type = "group",
                name = "Miss Options",
                inline = true,
                width = "full",
                args = {
                    useRandomMissSound = {
                        type = "toggle",
                        name = "Use Random MISS Sound",
                        desc = "Toggle between using a random sound or a specific sound for MISSes",
                        get = function() return self.db.profile.useRandomMissSound end,
                        set = function(_, value) self.db.profile.useRandomMissSound = value end,
                        order = 39
                    },
                    missSoundSelection = {
                        type = "select",
                        name = "MISS Sound Selection",
                        desc = "Select the sound to play on a Miss",
                        get = function()
                            local selectedMissSound = self.db.profile.selectedMissSound
                            for index, soundFile in ipairs(self.negativeSoundFiles) do
                                if soundFile == selectedMissSound then
                                    return index
                                end
                            end
                        end,
                        set = function(_, index)
                            self.db.profile.selectedMissSound = self.negativeSoundFiles[index]
                            self:PrintDebug("MISS sound set to: " .. self.negativeSoundFiles[index])
                        end,
                        values = self.negativeSoundFiles,
                        style = "dropdown", 
                        order = 32
                    },
                    playMissTestSound = {
                        type = "execute",
                        name = "Play Test MISS Sound",
                        desc = "Play a test sound for MISS",
                        func = function() self:PlaySelectedMissSound() end,
                        order = 33
                    },
                },
            },
            resistSoundOptions = {
                type = "group",
                name = "Resist Options",
                inline = true,
                width = "full",
                args = {
                    useRandomResistSound = {
                        type = "toggle",
                        name = "Use Random RESIST Sound",
                        desc = "Toggle between using a random sound or a specific sound for RESISTs",
                        get = function() return self.db.profile.useRandomResistSound end,
                        set = function(_, value) self.db.profile.useRandomResistSound = value end,
                        order = 49
                    },
                    resistSoundSelection = {
                        type = "select",
                        name = "RESIST Sound Selection",
                        desc = "Select the sound to play on a Resist",
                        get = function()
                            local selectedResistSound = self.db.profile.selectedResistSound
                            for index, soundFile in ipairs(self.negativeSoundFiles) do
                                if soundFile == selectedResistSound then
                                    return index
                                end
                            end
                        end,
                        set = function(_, index)
                            self.db.profile.selectedResistSound = self.negativeSoundFiles[index]
                            self:PrintDebug("RESIST sound set to: " .. self.negativeSoundFiles[index])
                        end,
                        values = self.negativeSoundFiles,
                        style = "dropdown", 
                        order = 42
                    },
                    playResistTestSound = {
                        type = "execute",
                        name = "Play Test RESIST Sound",
                        desc = "Play a test sound for RESIST",
                        func = function() self:PlaySelectedResistSound() end,
                        order = 43
                    },
                },
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
            useRandomCritSound = false,
            selectedCritSound = self.positiveSoundFiles[1], -- First positive sound as default
            useRandomMissSound = false,
            selectedMissSound = self.negativeSoundFiles[1], -- First negative sound as default
            useRandomResistSound = false,
            selectedResistSound = self.negativeSoundFiles[2], -- First negative sound as default
        },
    }
end

-- Play the selected sound
function CritDaddy:PlaySelectedCritSound()
    local selectedCritSound = self.db.profile.selectedCritSound
    if selectedCritSound and selectedCritSound ~= "" then
        local soundPath = self.SOUND_DIR .. "\\" .. selectedCritSound
        PlaySoundFile(soundPath, "Master")
    else
        self:Print("No specific crit sound selected.")
    end
end

function CritDaddy:PlaySelectedMissSound()
    local selectedMissSound = self.db.profile.selectedMissSound
    if selectedMissSound and selectedMissSound ~= "" then
        local soundPath = self.SOUND_DIR .. "\\" .. selectedMissSound
        PlaySoundFile(soundPath, "Master")
    else
        self:Print("No specific miss sound selected.")
    end
end

function CritDaddy:PlaySelectedResistSound()
    local selectedResistSound = self.db.profile.selectedResistSound
    if selectedResistSound and selectedResistSound ~= "" then
        local soundPath = self.SOUND_DIR .. "\\" .. selectedResistSound
        PlaySoundFile(soundPath, "Master")
    else
        self:Print("No specific resist sound selected.")
    end
end

-- Play a random sound
function CritDaddy:PlayRandomSound(type)
    local soundPath

    if type == "pos" then
        -- Select a random sound from positiveSounds
        soundPath = positiveSoundFiles[math.random(#positiveSoundFiles)]
    elseif type == "neg" then
        -- Select a random sound from negativeSounds
        soundPath = self.negativeSoundFiles[math.random(#self.negativeSoundFiles)]
    end

	if soundPath then
        PlaySoundFile(soundPath)
    end
end

-- Function to play sound based on user settings
function CritDaddy:PlayCritSound()
    if self.db.profile.useRandomCritSound then
        self:PlayRandomSound("pos")
    else
        self:PlaySelectedCritSound()
    end
end

-- Function to play sound based on user settings
function CritDaddy:PlayMissSound()
    if self.db.profile.useRandomMissSound then
        self:PlayRandomSound("neg")
    else
        self:PlaySelectedMissSound()
    end
end

-- Function to play sound based on user settings
function CritDaddy:PlayResistSound()
    if self.db.profile.useRandomResistSound then
        self:PlayRandomSound("neg")
    else
        self:PlaySelectedResistSound()
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

    -- If the source is not our player, exit the function
    if sourceGUID ~= UnitGUID("player") then
        return
    end

    -- Handling MISS events
    if eventType == "SWING_MISSED" or eventType == "SPELL_MISSED" or eventType == "RANGE_MISSED" then
        local missType = arg12 -- missType can be "MISS", "DODGE", "PARRY", etc.
        if missType == "MISS" then
            self:PrintDebug("Missed Attack")
            CritDaddy:PlayMissSound() -- Play a specific sound for MISS
        elseif missType == "RESIST" then
            self:PrintDebug("Resisted Attack")
            CritDaddy:PlayResistSound() -- Play a specific sound for RESIST
        end
    end

    -- Handling RESIST event
    if eventType == "SPELL_RESIST" then
        self:PrintDebug("Spell Resisted")
        CritDaddy:PlayResistSound() -- Play a specific sound for RESIST
    end

    -- Handling CRIT events
    if eventType == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Swing Damage: " .. amount)
            CritDaddy:PlayCritSound() -- Play a specific sound for CRIT
        elseif resisted then
		    self:PrintDebug("Resisted Attack")
            CritDaddy:PlayResistSound() -- Play a specific sound for RESIST
        end
    elseif eventType == "SPELL_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21
        if critical then
            self:PrintDebug("Critical Spell/Range Damage: " .. spellName .. " for " .. amount)
            CritDaddy:PlayCritSound() -- Play a specific sound for CRIT
        elseif resisted then
		    self:PrintDebug("Resisted Attack")
            CritDaddy:PlayResistSound() -- Play a specific sound for RESIST
        end
    elseif eventType == "SPELL_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = arg12, arg13, arg14, arg15, arg16, arg17, arg18
        if critical then
            self:PrintDebug("Critical Heal: " .. spellName .. " for " .. amount)
            CritDaddy:PlayCritSound() -- Play a specific sound for CRIT
        end
    end
end


-- swing_missed: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...
-- spell_missed: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...
-- range_missed: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...
-- swing_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- spell_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
-- range_damage: timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...
-- spell_heal:   timestamp, subevent, hideCastersourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overhealing, absorbed, critical