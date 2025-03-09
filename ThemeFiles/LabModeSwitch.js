// Code for mode switching
const difficultyValue = $(`select[data-name="Difficulty"]`).val() || ''; // Cached at init

// Define modes globally
const modes = {
    guided: { 
        ShowGuided: 'Yes', 
        ShowAdvanced: 'Yes', 
        ShowActivity: 'Yes'
        //visibility: () => { $('.hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .ShowGuided').show(); $('.knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowAdvanced').show(); }
    },
    advanced: { 
        ShowGuided: 'No', 
        ShowAdvanced: 'Yes', 
        ShowActivity: 'Yes' 
        //visibility: () => { $('.hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .ShowGuided').hide(); $('.knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowAdvanced').show(); }
    },
    expert: { 
        ShowGuided: 'No', 
        ShowAdvanced: 'No', 
        ShowActivity: 'No' 
        //visibility: () => { $('.hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .ShowGuided').hide(); $('.knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowAdvanced').hide(); }
    }
};

function modeSwitch() {
    const modeSwitchSelected = $('[data-name="LabMode"] option:selected').first().text() || null;
    if (debug) { console.log(`Mode selected: ${modeSwitchSelected}`); }

    const difficultyButton = $('.difficultybutton [data-name="Difficulty"]');
    const modeKey = modeSwitchSelected ? modeSwitchSelected.toLowerCase() : null;

    if (modeKey in modes) {
        const settings = modes[modeKey];
        for (const [name, value] of Object.entries(settings)) {
            if (typeof value === 'function') {
                value();
            } else {
                setSelectValue(name, value);
            }
        }
        if (difficultyButton.length) {
            difficultyButton.each((index, element) => {
                element.innerHTML = modeSwitchSelected; // Original case preserved
            });
            if (debug) { console.log(`Updated difficultybutton [data-name="Difficulty"] innerHTML to: ${modeSwitchSelected}`); }
        } else if (debug) {
            console.log("No difficultybutton [data-name=\"Difficulty\"] element found");
        }
        if (debug) { console.log(`Applied ${modeSwitchSelected} mode settings`); }
    } else if (modeSwitchSelected === null || modeKey === "select lab mode") {
        if (difficultyButton.length) {
            difficultyButton.each((index, element) => {
                element.innerHTML = difficultyValue || '';
            });
            if (debug) { console.log(`Updated difficultybutton [data-name="Difficulty"] innerHTML to Difficulty: ${difficultyValue}`); }
        } else if (debug) {
            console.log("No difficultybutton [data-name=\"Difficulty\"] element found");
        }
        if (debug) { console.log(`No mode applied (modeSwitchSelected: ${modeSwitchSelected})`); }
    } else if (modeSwitchSelected) {
        if (debug) { console.log(`Unknown mode: ${modeSwitchSelected}, no changes applied`); }
    }
}

// Helper Functions
function setSelectValue(name, value) {
    const $select = $(`select[data-name="${name}"]`);
    $select.find(`option[value="${value}"]`).prop('selected', true);
    $select.trigger('change');
}

// Create custom difficulty dropdown
function createCustomDifficultyDropdown() {
    const difficultyButton = $('.difficultybutton [data-name="Difficulty"]');
    if (!difficultyButton.length) {
        if (debug) { console.log("No difficultybutton [data-name=\"Difficulty\"] element found, skipping custom dropdown"); }
        return;
    }

    const defaultValue = difficultyButton[0].innerHTML.trim(); // Get original innerHTML
    if (debug) { console.log(`Original difficulty button value: ${defaultValue}`); }

    // If Expert, skip and leave original
    if (defaultValue.toLowerCase() === 'expert') {
        if (debug) { console.log("Default value is Expert, retaining original difficulty button"); }
        return;
    }

    // Hide original button
    difficultyButton.hide();
    if (debug) { console.log("Hid original difficultybutton [data-name=\"Difficulty\"]"); }

    // Create new dropdown
    const $newSelect = $('<select class="custom-difficulty" data-name="CustomDifficulty"></select>');
    const options = [
        { text: 'Guided', value: 'Guided' },
        { text: 'Advanced', value: 'Advanced' },
        { text: 'Expert', value: 'Expert' }
    ];

    // Filter options based on default value
    let availableOptions = options;
    if (defaultValue.toLowerCase() === 'advanced') {
        availableOptions = options.slice(1); // Only Advanced and Expert
        if (debug) { console.log("Default value is Advanced, limiting options to Advanced and Expert"); }
    }

    // Add options to dropdown
    availableOptions.forEach(option => {
        const $option = $(`<option value="${option.value}">${option.text}</option>`);
        if (option.text === defaultValue) {
            $option.prop('selected', true);
        }
        $newSelect.append($option);
    });

    // Append after the original button's parent
    difficultyButton.parent().after($newSelect);
    if (debug) { console.log(`Created custom difficulty dropdown with default: ${defaultValue}`); }

    // Event listener for new dropdown
    $newSelect.on('change', () => {
        const selectedMode = $newSelect.val();
        if (debug) { console.log(`Custom difficulty dropdown changed to: ${selectedMode}`); }
        const modeKey = selectedMode.toLowerCase();
        if (modeKey in modes) {
            const settings = modes[modeKey];
            for (const [name, value] of Object.entries(settings)) {
                if (typeof value === 'function') {
                    value();
                } else {
                    setSelectValue(name, value);
                }
            }
            if (debug) { console.log(`Applied ${selectedMode} mode settings from custom dropdown`); }
        }
    });
}

// Setup event listeners
function initializeModeSwitch() {
    const $modeSwitchItems = $('[data-name="LabMode"]');
    if (debug) { console.log(`Found ${$modeSwitchItems.length} mode switch elements`); }

    $modeSwitchItems.each((index, element) => {
        element.addEventListener('click', () => {
            modeSwitch();
            if (debug) { console.log(`Mode switch triggered by element ${index}`); }
        });
    });

    // Initialize custom dropdown
    createCustomDifficultyDropdown();
}

// Initialize the Mode Switch
try {
    initializeModeSwitch();
} catch (err) {
    console.error("Mode switch initialization failed:", err);
}
