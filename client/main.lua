-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local isLoggedIn = LocalPlayer.state.isLoggedIn
local currentArea = nil
local activeSalvage = nil
local playerSkill = 1
local playerXP = 0
local hasJob = false
local blips = {}
local salvageBlip = nil
local activeContract = nil

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    SetupJobCenter()
    SetupSalvageBlips()
    FetchSkillLevel()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
    RemoveBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    CheckJob()
end)

-- Check if player has the salvage job
function CheckJob()
    hasJob = PlayerData.job.name == Config.JobName
    if hasJob then
        SetupSalvageBlips()
    else
        RemoveBlips()
    end
end

-- Set up job center
function SetupJobCenter()
    -- Create job center blip
    local jobBlip = AddBlipForCoord(Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z)
    SetBlipSprite(jobBlip, Config.JobCenter.blip.sprite)
    SetBlipDisplay(jobBlip, 4)
    SetBlipScale(jobBlip, Config.JobCenter.blip.scale)
    SetBlipColour(jobBlip, Config.JobCenter.blip.color)
    SetBlipAsShortRange(jobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.JobCenter.blip.label)
    EndTextCommandSetBlipName(jobBlip)
    table.insert(blips, jobBlip)
    
    -- Create job center ped
    local pedModel = Config.JobCenter.ped.model
    RequestModel(GetHashKey(pedModel))
    while not HasModelLoaded(GetHashKey(pedModel)) do
        Wait(1)
    end
    
    local jobPed = CreatePed(4, GetHashKey(pedModel), Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z - 1, Config.JobCenter.coords.w, false, true)
    TaskStartScenarioInPlace(jobPed, Config.JobCenter.ped.scenario, 0, true)
    FreezeEntityPosition(jobPed, true)
    SetEntityInvincible(jobPed, true)
    SetBlockingOfNonTemporaryEvents(jobPed, true)
    
    -- Set up interaction
    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(jobPed, {
            options = {
                {
                    icon = "fas fa-briefcase",
                    label = "Talk to Salvage Manager",
                    job = Config.JobName,
                    action = function()
                        OpenJobMenu()
                    end,
                },
                {
                    icon = "fas fa-briefcase",
                    label = "Apply for Salvage Diver Job",
                    canInteract = function()
                        return PlayerData.job.name ~= Config.JobName
                    end,
                    action = function()
                        ApplyForJob()
                    end,
                }
            },
            distance = 2.5,
        })
    else
        -- Proximity prompt alternative
        CreateThread(function()
            while true do
                local sleep = 1000
                local pos = GetEntityCoords(PlayerPedId())
                local dist = #(pos - vector3(Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z))
                
                if dist < 5.0 then
                    sleep = 0
                    if dist < 2.0 then
                        if PlayerData.job.name == Config.JobName then
                            DrawText3D(Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z + 1.0, "[E] Talk to Salvage Manager")
                            if IsControlJustPressed(0, 38) then -- E key
                                OpenJobMenu()
                            end
                        else
                            DrawText3D(Config.JobCenter.coords.x, Config.JobCenter.coords.y, Config.JobCenter.coords.z + 1.0, "[E] Apply for Salvage Diver Job")
                            if IsControlJustPressed(0, 38) then -- E key
                                ApplyForJob()
                            end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end
end

-- Create blips for salvage areas
function SetupSalvageBlips()
    RemoveBlips()
    
    -- Only create salvage area blips if player has the job
    if PlayerData.job.name == Config.JobName then
        for i, area in ipairs(Config.SalvageAreas) do
            local areaBlip = AddBlipForRadius(area.coords.x, area.coords.y, area.coords.z, area.radius)
            SetBlipRotation(areaBlip, 0)
            SetBlipColour(areaBlip, 60)
            SetBlipAlpha(areaBlip, 75)
            table.insert(blips, areaBlip)
            
            local centerBlip = AddBlipForCoord(area.coords.x, area.coords.y, area.coords.z)
            SetBlipSprite(centerBlip, area.blip.sprite)
            SetBlipDisplay(centerBlip, 4)
            SetBlipScale(centerBlip, area.blip.scale)
            SetBlipColour(centerBlip, area.blip.color)
            SetBlipAsShortRange(centerBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(area.blip.label)
            EndTextCommandSetBlipName(centerBlip)
            table.insert(blips, centerBlip)
        end
    end
end

-- Remove all blips
function RemoveBlips()
    for i, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
    
    if salvageBlip then
        RemoveBlip(salvageBlip)
        salvageBlip = nil
    end
end

-- Apply for the salvage diver job
function ApplyForJob()
    TriggerServerEvent("ss-salvagediver:server:applyForJob")
end

-- Open job menu
function OpenJobMenu()
    if PlayerData.job.name ~= Config.JobName then
        QBCore.Functions.Notify("You don't work as a salvage diver.", "error")
        return
    end
    
    local headerMenu = {
        {
            header = "Salvage Diving Operations",
            isMenuHeader = true
        }
    }
    
    -- Add options to the menu
    table.insert(headerMenu, {
        header = "Get Contract",
        txt = "Accept a legal salvage contract",
        params = {
            event = "ss-salvagediver:client:showContracts"
        }
    })
    
    table.insert(headerMenu, {
        header = "Return Salvaged Items",
        txt = "Cash in your salvaged items",
        params = {
            event = "ss-salvagediver:client:returnItems"
        }
    })
    
    if Config.Debug then
        table.insert(headerMenu, {
            header = "🐞 Debug Info",
            txt = "XP: " .. playerXP .. " | Level: " .. playerSkill,
            params = {
                event = ""
            }
        })
    end
    
    table.insert(headerMenu, {
        header = "Close Menu",
        txt = "",
        params = {
            event = ""
        }
    })
    
    -- Open the menu with proper parameters
    exports['qb-menu']:openMenu(headerMenu)
end

-- Show available contracts
RegisterNetEvent("ss-salvagediver:client:showContracts", function()
    local contractMenu = {
        {
            header = "Available Salvage Contracts",
            isMenuHeader = true
        }
    }
    
    for i, area in ipairs(Config.SalvageAreas) do
        table.insert(contractMenu, {
            header = area.name,
            txt = "Accept a salvage contract at " .. area.name,
            params = {
                event = "ss-salvagediver:client:acceptContract",
                args = i
            }
        })
    end
    
    table.insert(contractMenu, {
        header = "← Go Back",
        txt = "",
        params = {
            event = "ss-salvagediver:client:openJobMenu"
        }
    })
    
    exports['qb-menu']:openMenu(contractMenu)
end)

-- Open job menu (for going back)
RegisterNetEvent("ss-salvagediver:client:openJobMenu", function()
    OpenJobMenu()
end)

-- Accept a salvage contract
RegisterNetEvent("ss-salvagediver:client:acceptContract", function(areaIndex)
    local area = Config.SalvageAreas[areaIndex]
    if not area then return end
    
    activeContract = {
        area = areaIndex,
        name = area.name,
        location = area.coords
    }
    
    -- Create a blip for the active contract
    if salvageBlip then
        RemoveBlip(salvageBlip)
    end
    
    salvageBlip = AddBlipForCoord(area.coords.x, area.coords.y, area.coords.z)
    SetBlipSprite(salvageBlip, 310) -- Different sprite for active contract
    SetBlipColour(salvageBlip, 47)
    SetBlipScale(salvageBlip, 1.0)
    SetBlipRoute(salvageBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Active Contract: " .. area.name)
    EndTextCommandSetBlipName(salvageBlip)
    
    QBCore.Functions.Notify(Config.Text.contract_accepted, "success")
    
    -- Start the contract monitoring
    StartContractMonitoring()
end)

-- Return salvaged items for payment
RegisterNetEvent("ss-salvagediver:client:returnItems", function()
    TriggerServerEvent("ss-salvagediver:server:returnItems")
end)

-- Start monitoring if player is in contract area
function StartContractMonitoring()
    CreateThread(function()
        while activeContract do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local areaCoords = activeContract.location
            local dist = #(playerCoords - areaCoords)
            local area = Config.SalvageAreas[activeContract.area]
            
            -- Check if player is in the contract area and underwater
            if dist < area.radius and IsEntityInWater(PlayerPedId()) then
                if not activeSalvage then
                    -- Start salvage process
                    QBCore.Functions.Notify("You've reached the salvage area. Start searching!", "success")
                    SetupSalvageActions(area)
                end
            end
            
            Wait(1000)
        end
    end)
end

-- Setup salvage interactions in the area
function SetupSalvageActions(area)
    CreateThread(function()
        while activeContract and IsEntityInWater(PlayerPedId()) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local areaCoords = area.coords
            local dist = #(playerCoords - areaCoords)
            
            if dist < area.radius then
                -- Display UI helper
                DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z, "[E] Start Salvaging")
                
                if IsControlJustPressed(0, 38) then -- E key
                    StartSalvage(area)
                end
            else
                break -- Player left the area
            end
            
            Wait(0)
        end
    end)
end

-- Start the salvage minigame/process
function StartSalvage(area)
    if activeSalvage then return end
    activeSalvage = true
    
    -- Check if player has required equipment
    local hasEquipment = QBCore.Functions.HasItem(Config.RequiredItems.tank) and QBCore.Functions.HasItem(Config.RequiredItems.basic_tools)
    
    if not hasEquipment then
        QBCore.Functions.Notify(Config.Text.no_equipment, "error")
        activeSalvage = false
        return
    end
    
    -- Get difficulty based on skill level
    local difficultySettings = Config.Minigame.difficulty[playerSkill]
    
    -- Start minigame animation
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
    QBCore.Functions.Progressbar("salvage_searching", "Searching for valuables...", math.random(Config.SalvageDuration.min, Config.SalvageDuration.max) * 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasksImmediately(PlayerPedId())
        
        -- Complete the salvage and give rewards
        TriggerServerEvent("ss-salvagediver:server:completeSalvage", activeContract.area, playerSkill)
        
        activeSalvage = false
        Wait(5000) -- Cooldown between salvage attempts
    end, function() -- Cancel
        ClearPedTasksImmediately(PlayerPedId())
        QBCore.Functions.Notify("Salvage cancelled.", "error")
        activeSalvage = false
    end)
end

-- Fetch player's skill level from server
function FetchSkillLevel()
    TriggerServerEvent("ss-salvagediver:server:getSkillLevel")
end

-- Update player skill level
RegisterNetEvent("ss-salvagediver:client:updateSkillLevel", function(xp, level)
    playerXP = xp
    playerSkill = level
    
    -- Show level up notification if debug is enabled
    if Config.Debug then
        QBCore.Functions.Notify("Salvage Skill: " .. Config.RewardSystem.skill_levels[level].label .. " (XP: " .. xp .. ")", "primary")
    end
end)

-- Show progress when finding an item
RegisterNetEvent("ss-salvagediver:client:itemFound", function(item, label)
    QBCore.Functions.Notify(string.format(Config.Text.item_found, label), "success")
end)

-- Complete a contract
RegisterNetEvent("ss-salvagediver:client:completeContract", function()
    QBCore.Functions.Notify(Config.Text.contract_completed, "success")
    
    if salvageBlip then
        RemoveBlip(salvageBlip)
        salvageBlip = nil
    end
    
    activeContract = nil
end)

-- Helper function for 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- UI related functions
CreateThread(function()
    while true do
        local sleep = 1000
        
        if isLoggedIn and PlayerData.job and PlayerData.job.name == Config.JobName and IsEntityInWater(PlayerPedId()) then
            sleep = 0
            
            -- Get player oxygen level
            local oxygenLevel = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            
            -- Get player depth
            local playerCoords = GetEntityCoords(PlayerPedId())
            local waterHeight = GetWaterHeight(playerCoords.x, playerCoords.y, playerCoords.z)
            local depth = math.abs(math.floor((waterHeight - playerCoords.z) * 10) / 10)
            
            -- Display UI if enabled
            if Config.UI.show_oxygen or Config.UI.show_depth then
                -- Draw background
                DrawRect(0.93, 0.93, 0.14, 0.13, 0, 0, 0, 100)
                
                -- Draw oxygen bar
                if Config.UI.show_oxygen then
                    DrawText2D(0.87, 0.88, 0.35, "Oxygen: " .. math.floor(oxygenLevel) .. "%")
                    DrawRect(0.93, 0.91, 0.12, 0.015, 0, 0, 0, 150)
                    DrawRect(0.93 - (0.12 / 2) + ((oxygenLevel / 100) * 0.12 / 2), 0.91, (oxygenLevel / 100) * 0.12, 0.015, 0, 150, 255, 150)
                    
                    -- Oxygen warning
                    if oxygenLevel < Config.UI.oxygen_warning_level then
                        DrawText2D(0.93, 0.95, 0.4, "LOW OXYGEN!", {r = 255, g = 0, b = 0})
                    end
                end
                
                -- Draw depth meter
                if Config.UI.show_depth then
                    DrawText2D(0.87, 0.93, 0.35, "Depth: " .. depth .. "m")
                    
                    -- Depth warning
                    if depth > Config.UI.max_salvage_depth then
                        DrawText2D(0.93, 0.97, 0.35, "TOO DEEP!", {r = 255, g = 0, b = 0})
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Helper function for 2D text
function DrawText2D(x, y, scale, text, color)
    color = color or {r = 255, g = 255, b = 255}
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(color.r, color.g, color.b, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Initialize when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1000)
        PlayerData = QBCore.Functions.GetPlayerData()
        isLoggedIn = LocalPlayer.state.isLoggedIn
        if isLoggedIn then
            SetupJobCenter()
            CheckJob()
            FetchSkillLevel()
        end
    end
end)