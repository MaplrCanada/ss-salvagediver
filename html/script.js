// QBCore Salvage Diver UI - Main JavaScript
$(function() {
    // Listener for NUI messages from client script
    window.addEventListener('message', function(event) {
        let data = event.data;
        
        switch (data.action) {
            case 'show': // Show the UI
                $('#salvage-ui').fadeIn(300);
                break;
                
            case 'hide': // Hide the UI
                $('#salvage-ui').fadeOut(300);
                break;
                
            case 'updateStatus': // Update player status
                updatePlayerStatus(data);
                break;
                
            case 'updateContract': // Update contract info
                updateContractInfo(data.contract);
                break;
                
            case 'updateInventory': // Update salvaged items
                updateInventory(data.items);
                break;
                
            case 'startMinigame': // Start salvage minigame
                startMinigame(data.difficulty);
                break;
                
            case 'showAlert': // Show alert popup
                showAlert(data.title, data.message);
                break;
                
            case 'updateHUD': // Update HUD elements (oxygen, depth)
                updateHUD(data.oxygen, data.depth);
                break;
        }
    });
    
    // Close UI button
    $('#close-ui').click(function() {
        $('#salvage-ui').fadeOut(300);
        $.post('https://qb-salvage/closeUI', JSON.stringify({}));
    });
    
    // Return items button
    $('#return-items').click(function() {
        $.post('https://qb-salvage/returnItems', JSON.stringify({}));
    });
    
    // Minigame start button
    $('#minigame-start').click(function() {
        $(this).prop('disabled', true);
        startSalvageSequence();
    });
    
    // Minigame cancel button
    $('#minigame-cancel').click(function() {
        $('#minigame-container').addClass('hidden');
        $.post('https://qb-salvage/cancelMinigame', JSON.stringify({}));
    });
    
    // Alert confirm button
    $('#alert-confirm').click(function() {
        $('#alert-popup').addClass('hidden');
    });
    
    // Initialize UI (hide elements that should be hidden initially)
    initializeUI();
});

// Initialize UI
function initializeUI() {
    $('#salvage-ui').hide();
    $('#alert-popup').addClass('hidden');
    $('#minigame-container').addClass('hidden');
    $('#active-contract').addClass('hidden');
    $('#no-contract-message').removeClass('hidden');
}

// Update player status with XP and skill level
function updatePlayerStatus(data) {
    $('#skill-level').text(data.skillLabel || 'Novice Diver');
    $('#xp-value').text(data.xp || 0);
    
    // Update XP progress bar (based on xp and required xp for next level)
    let progress = 0;
    if (data.requiredXP > 0) {
        progress = (data.xp / data.requiredXP) * 100;
    }
    $('#xp-progress').css('width', progress + '%');
}

// Update HUD elements (oxygen and depth)
function updateHUD(oxygen, depth) {
    $('#oxygen-value').text(Math.floor(oxygen || 100));
    $('#depth-value').text(depth || 0);
    
    // Change color based on oxygen level
    if (oxygen < 25) {
        $('#oxygen-value').addClass('danger').removeClass('warning');
    } else if (oxygen < 50) {
        $('#oxygen-value').addClass('warning').removeClass('danger');
    } else {
        $('#oxygen-value').removeClass('warning danger');
    }
    
    // Change color based on depth (if too deep)
    if (depth > 30) {
        $('#depth-value').addClass('danger');
    } else {
        $('#depth-value').removeClass('danger');
    }
}

// Update contract information
function updateContractInfo(contract) {
    if (!contract || !contract.name) {
        $('#active-contract').addClass('hidden');
        $('#no-contract-message').removeClass('hidden');
        return;
    }
    
    $('#no-contract-message').addClass('hidden');
    $('#active-contract').removeClass('hidden');
    
    $('#contract-name').text(contract.name);
    $('#contract-location').text(contract.location || 'Unknown');
    $('#contract-status').text(contract.status || 'In Progress');
    
    // Update potential rewards list
    if (contract.rewards && contract.rewards.length > 0) {
        let rewardsHTML = '';
        contract.rewards.forEach(reward => {
            rewardsHTML += `<li>${reward.label} - $${reward.payment}</li>`;
        });
        $('#rewards-list').html(rewardsHTML);
    } else {
        $('#rewards-list').html('<li>No information available</li>');
    }
}

// Update inventory of salvaged items
function updateInventory(items) {
    let inventoryHTML = '';
    
    if (items && items.length > 0) {
        items.forEach(item => {
            inventoryHTML += `
                <div class="inventory-item" data-item="${item.name}">
                    <div class="item-img">
                        <img src="nui://qb-inventory/html/images/${item.image}" alt="${item.label}">
                        <div class="item-count">${item.amount}</div>
                    </div>
                    <div class="item-label">${item.label}</div>
                    <div class="item-value">$${item.value}</div>
                </div>
            `;
        });
    } else {
        inventoryHTML = '<div class="no-items">No salvaged items in inventory</div>';
    }
    
    $('#salvage-inventory').html(inventoryHTML);
}

// Show alert popup
function showAlert(title, message) {
    $('#alert-title').text(title || 'Alert');
    $('#alert-message').text(message || '');
    $('#alert-popup').removeClass('hidden');
}

// Start salvage minigame
function startMinigame(difficulty) {
    // Clear previous minigame if any
    $('#minigame-grid').empty();
    $('#minigame-start').prop('disabled', false);
    
    // Set up difficulty
    let gridSize = 3; // Default easy
    let timeLimit = 10000; // 10 seconds for easy
    
    if (difficulty === 'medium') {
        gridSize = 4;
        timeLimit = 8000;
    } else if (difficulty === 'hard') {
        gridSize = 5;
        timeLimit = 6000;
    } else if (difficulty === 'expert') {
        gridSize = 6;
        timeLimit = 5000;
    }
    
    // Create grid based on difficulty
    createMinigameGrid(gridSize);
    
    // Show minigame container
    $('#minigame-container').removeClass('hidden');
    
    // Store the difficulty and time limit for use when starting
    $('#minigame-container').data('difficulty', difficulty);
    $('#minigame-container').data('timeLimit', timeLimit);
}

// Create minigame grid
function createMinigameGrid(size) {
    $('#minigame-grid').empty();
    $('#minigame-grid').css('grid-template-columns', `repeat(${size}, 1fr)`);
    
    for (let i = 0; i < size * size; i++) {
        let cell = $('<div>').addClass('grid-cell');
        $('#minigame-grid').append(cell);
    }
}

// Start the salvage sequence (minigame)
function startSalvageSequence() {
    const difficulty = $('#minigame-container').data('difficulty');
    const timeLimit = $('#minigame-container').data('timeLimit');
    
    let targetCells = [];
    const gridSize = difficulty === 'easy' ? 3 : 
                    difficulty === 'medium' ? 4 : 
                    difficulty === 'hard' ? 5 : 6;
    
    // Number of targets based on difficulty
    const numTargets = difficulty === 'easy' ? 3 : 
                     difficulty === 'medium' ? 4 : 
                     difficulty === 'hard' ? 5 : 6;
    
    // Select random targets
    let allCells = Array.from(Array(gridSize * gridSize).keys());
    for (let i = 0; i < numTargets; i++) {
        if (allCells.length > 0) {
            let randomIndex = Math.floor(Math.random() * allCells.length);
            let target = allCells.splice(randomIndex, 1)[0];
            targetCells.push(target);
        }
    }
    
    // Show targets briefly
    targetCells.forEach(index => {
        $($('#minigame-grid .grid-cell')[index]).addClass('target-preview');
    });
    
    // After brief preview, start the game
    setTimeout(() => {
        $('.grid-cell').removeClass('target-preview');
        
        // Make cells clickable
        $('.grid-cell').click(function() {
            let index = $(this).index();
            
            if (targetCells.includes(index)) {
                $(this).addClass('target-hit');
                targetCells = targetCells.filter(cell => cell !== index);
                
                // Check if all targets hit
                if (targetCells.length === 0) {
                    endMinigame(true);
                }
            } else {
                $(this).addClass('target-miss');
                // Allow some misses based on difficulty
                const allowedMisses = difficulty === 'easy' ? 2 : 
                                   difficulty === 'medium' ? 1 : 0;
                
                if ($('.target-miss').length > allowedMisses) {
                    endMinigame(false);
                }
            }
        });
        
        // Start timer
        let timer = setTimeout(() => {
            endMinigame(false); // Failed if time runs out
        }, timeLimit);
        
        // Store timer reference
        $('#minigame-container').data('timer', timer);
        
    }, 2000); // Show targets for 2 seconds
}

// End the minigame
function endMinigame(success) {
    // Clear any timers
    clearTimeout($('#minigame-container').data('timer'));
    
    // Make cells non-clickable
    $('.grid-cell').off('click');
    
    // Show result
    if (success) {
        showAlert('Success!', 'You successfully salvaged an item!');
    } else {
        showAlert('Failed', 'Salvage attempt failed. Try again!');
    }
    
    // Hide minigame after a short delay
    setTimeout(() => {
        $('#minigame-container').addClass('hidden');
        
        // Send result to client script
        $.post('https://qb-salvage/minigameResult', JSON.stringify({
            success: success
        }));
    }, 1500);
}

// Handle key presses (ESC to close UI)
$(document).keyup(function(e) {
    if (e.key === "Escape") {
        $('#salvage-ui').fadeOut(300);
        $.post('https://qb-salvage/closeUI', JSON.stringify({}));
    }
});