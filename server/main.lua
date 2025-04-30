-- server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Player skill levels tracking
local PlayerSkills = {}

-- Initialize a player's skills when they log in
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Initialize player skills if they don't exist
    if not PlayerSkills[citizenId] then
        PlayerSkills[citizenId] = {
            xp = 0,
            level = 1
        }
        -- Save to database (optional implementation)
        SavePlayerSkills(citizenId)
    end
end)

-- Save player skills to database (placeholder function)
function SavePlayerSkills(citizenId)
    -- You can implement database saving here if needed
    -- Example using QBCore's database export:
    -- exports.oxmysql:execute('INSERT INTO player_skills (citizenid, skill_name, xp, level) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE xp = ?, level = ?',
    --     {citizenId, 'salvage_diving', PlayerSkills[citizenId].xp, PlayerSkills[citizenId].level, PlayerSkills[citizenId].xp, PlayerSkills[citizenId].level})
end

-- Get player skill level
RegisterNetEvent('ss-salvagediver:server:getSkillLevel', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- Initialize if doesn't exist
    if not PlayerSkills[citizenId] then
        PlayerSkills[citizenId] = {
            xp = 0,
            level = 1
        }
    end
    
    -- Send skill data to client
    TriggerClientEvent('ss-salvagediver:client:updateSkillLevel', src, PlayerSkills[citizenId].xp, PlayerSkills[citizenId].level)
end)

-- Apply for the salvage diver job
RegisterNetEvent('ss-salvagediver:server:applyForJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has the required items
    local hasEquipment = Player.Functions.HasItem(Config.RequiredItems.tank) and Player.Functions.HasItem(Config.RequiredItems.basic_tools)
    
    if hasEquipment then
        -- Set job
        Player.Functions.SetJob(Config.JobName, 0) -- Grade 0 (Trainee)
        TriggerClientEvent('QBCore:Notify', src, "You are now employed as a Salvage Diver!", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, Config.Text.no_equipment, "error")
    end
end)

-- Complete a salvage operation
RegisterNetEvent('ss-salvagediver:server:completeSalvage', function(areaIndex, skillLevel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    local area = Config.SalvageAreas[areaIndex]
    
    if not area then return end
    
    -- Calculate skill bonus
    local skillBonus = Config.RewardSystem.skill_bonuses[skillLevel] or 1.0
    
    -- Select a random reward based on chances
    local rewards = area.rewards
    local foundItem = nil
    
    -- Sort rewards by chance (higher chance items first for random selection)
    table.sort(rewards, function(a, b)
        return a.chance > b.chance
    end)
    
    -- Check each reward with its chance
    for _, reward in ipairs(rewards) do
        local chance = reward.chance * skillBonus
        if math.random(1, 100) <= chance then
            foundItem = reward
            break
        end
    end
    
    -- Fallback to most common item if nothing was found
    if not foundItem and #rewards > 0 then
        foundItem = rewards[1]
    end
    
    if foundItem then
        -- Give the item to the player
        Player.Functions.AddItem(foundItem.item, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[foundItem.item], "add")
        TriggerClientEvent('ss-salvagediver:client:itemFound', src, foundItem.item, foundItem.label)
        
        -- Add XP
        local xpGain = Config.RewardSystem.base_xp
        if foundItem.chance < 30 then -- Rare item
            xpGain = xpGain * Config.RewardSystem.bonus_xp_multiplier
        end
        
        -- Update player skills
        if PlayerSkills[citizenId] then
            PlayerSkills[citizenId].xp = PlayerSkills[citizenId].xp + xpGain
            
            -- Check for level up
            local currentLevel = PlayerSkills[citizenId].level
            local nextLevel = currentLevel + 1
            
            while nextLevel <= #Config.RewardSystem.skill_levels and PlayerSkills[citizenId].xp >= Config.RewardSystem.skill_levels[nextLevel].required_xp do
                PlayerSkills[citizenId].level = nextLevel
                TriggerClientEvent('QBCore:Notify', src, "Your salvage skills improved! You are now a " .. Config.RewardSystem.skill_levels[nextLevel].label, "success")
                nextLevel = nextLevel + 1
            end
            
            -- Save skills
            SavePlayerSkills(citizenId)
            
            -- Update client
            TriggerClientEvent('ss-salvagediver:client:updateSkillLevel', src, PlayerSkills[citizenId].xp, PlayerSkills[citizenId].level)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You couldn't find anything valuable this time.", "error")
    end
end)

-- Return salvaged items for payment
RegisterNetEvent('ss-salvagediver:server:returnItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local totalPayment = 0
    local itemsReturned = false
    
    -- Check for salvage items from legal areas
    for _, area in ipairs(Config.SalvageAreas) do
        for _, reward in ipairs(area.rewards) do
            local item = Player.Functions.GetItemByName(reward.item)
            if item and item.amount > 0 then
                -- Calculate payment
                local payment = reward.payment * item.amount
                
                -- Apply skill bonus if available
                local citizenId = Player.PlayerData.citizenid
                if PlayerSkills[citizenId] and PlayerSkills[citizenId].level then
                    local skillBonus = Config.RewardSystem.skill_bonuses[PlayerSkills[citizenId].level] or 1.0
                    payment = payment * skillBonus
                end
                
                -- Remove items and add payment
                Player.Functions.RemoveItem(reward.item, item.amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item], "remove", item.amount)
                
                totalPayment = totalPayment + payment
                itemsReturned = true
            end
        end
    end
    
    -- Check for valuable items from hidden areas (higher value but possibly illegal)
    for _, area in ipairs(Config.HiddenAreas) do
        for _, reward in ipairs(area.rewards) do
            local item = Player.Functions.GetItemByName(reward.item)
            if item and item.amount > 0 then
                -- Calculate payment (no skill bonus for illegal items)
                local payment = reward.payment * item.amount
                
                -- Remove items and add payment
                Player.Functions.RemoveItem(reward.item, item.amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item], "remove", item.amount)
                
                totalPayment = totalPayment + payment
                itemsReturned = true
            end
        end
    end
    
    -- Give payment if items were returned
    if itemsReturned then
        Player.Functions.AddMoney("cash", math.floor(totalPayment), "salvage-payment")
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. math.floor(totalPayment) .. " for your salvaged items!", "success")
        TriggerClientEvent('ss-salvagediver:client:completeContract', src)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have any salvaged items to return.", "error")
    end
end)

-- Register items with QBCore if they don't exist
RegisterNetEvent('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Register all salvage items
        local itemsToRegister = {}
        
        -- Get all salvage items from config
        for _, area in ipairs(Config.SalvageAreas) do
            for _, reward in ipairs(area.rewards) do
                itemsToRegister[reward.item] = {
                    name = reward.item,
                    label = reward.label,
                    weight = 1000,
                    type = "item",
                    image = "salvage_" .. reward.item .. ".png",
                    unique = false,
                    useable = false,
                    shouldClose = true,
                    combinable = nil,
                    description = "A salvaged item: " .. reward.label
                }
            end
        end
        
        for _, area in ipairs(Config.HiddenAreas) do
            for _, reward in ipairs(area.rewards) do
                itemsToRegister[reward.item] = {
                    name = reward.item,
                    label = reward.label,
                    weight = 1000,
                    type = "item",
                    image = "salvage_" .. reward.item .. ".png", 
                    unique = false,
                    useable = false,
                    shouldClose = true,
                    combinable = nil,
                    description = "A valuable salvaged item: " .. reward.label
                }
            end
        end
        
        -- Register equipment items
        itemsToRegister[Config.RequiredItems.tank] = Config.Items.diving_gear
        itemsToRegister[Config.RequiredItems.basic_tools] = Config.Items.basic_salvage_tools
        
        -- Actually register the items with QBCore 
        -- NOTE: This is for demonstration - actual implementation varies based on server setup
        -- Check if QBCore's shared items are accessible
        if QBCore.Shared.Items then
            for itemName, itemData in pairs(itemsToRegister) do
                if not QBCore.Shared.Items[itemName] then
                    QBCore.Shared.Items[itemName] = itemData
                    print("^2[ss-salvagediver]^7 Registered item: " .. itemName)
                end
            end
        else
            print("^1[ss-salvagediver]^7 Could not access QBCore.Shared.Items - items not registered automatically")
        end
    end
end)

-- Add some hidden treasure on server start
RegisterNetEvent('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Spawn some hidden treasures in the hidden areas
        -- This can be expanded to create more dynamic treasure spawns
        print("^2[ss-salvagediver]^7 Resource started. Hidden treasures activated.")
    end
end)