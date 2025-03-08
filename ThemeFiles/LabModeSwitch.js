// Code for mode switching
function modeSwitch() {
    const difficultyValue = $(`select[data-name="${name}"]`).val() || '';
    if (debug) { console.log(`Current Difficulty: ${difficultyValue}`); }
    const modeSwitchSelected = $('[data-name="LabMode"] option:selected').first().text() || null; // Removed .toLowerCase()
    if (debug) { console.log(`Mode selected: ${modeSwitchSelected}`); }

    // Cached selectors for visibility toggles (kept for reference, unused when commented)
    //const $hints = $('.hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .ShowGuided');
    //const $knowledge = $('.knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowAdvanced');

    const modes = {
        guided: { 
            ShowGuided: 'Yes', 
            ShowAdvanced: 'Yes', 
            ShowActivity: 'Yes'
            // Uncomment below to work with objects outside of "Sections"
            //visibility: () => { $hints.show(); $knowledge.show(); }
        },
        advanced: { 
            ShowGuided: 'No', 
            ShowAdvanced: 'Yes', 
            ShowActivity: 'Yes' 
            // Uncomment below to work with objects outside of "Sections"
            //visibility: () => { $hints.hide(); $knowledge.show(); }
        },
        expert: { 
            ShowGuided: 'No', 
            ShowAdvanced: 'No', 
            ShowActivity: 'No' 
            // Uncomment below to work with objects outside of "Sections"
            //visibility: () => { $hints.hide(); $knowledge.hide(); }
        }
    };

    // Update the Difficulty button on page0 to reflect the change
    const difficultyButton = $('.difficultybutton [data-name="Difficulty"]');
    const modeKey = modeSwitchSelected ? modeSwitchSelected.toLowerCase() : null; // Case-insensitive key check
    if (modeKey in modes) {
        const settings = modes[modeKey];
        for (const [name, value] of Object.entries(settings)) {
            if (typeof value === 'function') {
                value(); // Skipped when commented out
            } else {
                setSelectValue(name, value);
            }
        }
        // Update innerHTML to modeSwitchSelected (original case) for valid modes
        if (difficultyButton.length) {
            difficultyButton.each((index, element) => {
                element.innerHTML = modeSwitchSelected; // Original case preserved
            });
            if (debug) { console.log(`Updated difficultybutton [data-name="Difficulty"] innerHTML to: ${modeSwitchSelected}`); }
        } else if (debug) {
            console.log("No difficultybutton [data-name=\"Difficulty\"] element found");
        }
        if (debug) { console.log(`Applied ${modeSwitchSelected} mode settings`); }
    } else if (modeSwitchSelected === null || modeSwitchSelected === '' || modeKey === "select lab mode") {
        // Update innerHTML to Difficulty toggle value when null or "select lab mode"
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
}

// Initialize the Mode Switch
try {
    initializeModeSwitch();
} catch (err) {
    console.error("Mode switch initialization failed:", err);
}
