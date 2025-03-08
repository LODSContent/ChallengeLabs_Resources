// Code for mode switching
let isSwitching = false; // Recursion guard
const difficultyValue = $(`select[data-name="Difficulty"]`).val() || ''; // Cached at init

function debounce(func, wait) {
    let timeout;
    return function (...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
}

const modeSwitch = debounce(() => {
    if (isSwitching) {
        if (debug) { console.log("Recursion detected, aborting modeSwitch"); }
        return;
    }
    isSwitching = true;

    if (debug) { console.log(`Current Difficulty: ${difficultyValue}`); }
    const modeSwitchSelected = $('[data-name="LabMode"] option:selected').first().text() || null;
    if (debug) { console.log(`Mode selected: ${modeSwitchSelected}`); }

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

    const difficultyButton = $('.difficultybutton [data-name="Difficulty"]');
    const modeKey = modeSwitchSelected ? modeSwitchSelected.toLowerCase() : null;
    if (modeKey in modes) {
        const settings = modes[modeKey];
        for (const [name, value] of Object.entries(settings)) {
            if (typeof value === 'function') {
                value(); // Skipped when commented out
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
    } else if (modeSwitchSelected === null || modeSwitchSelected === '' || modeKey === "select lab mode") {
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

    // Log current LabMode state post-update
    const currentMode = $('[data-name="LabMode"] option:selected').first().text() || null;
    if (debug) { console.log(`Post-update LabMode state: ${currentMode}`); }

    isSwitching = false; // Reset guard
}, 100); // 100ms debounce

// Helper Functions
function setSelectValue(name, value) {
    const $select = $(`select[data-name="${name}"]`);
    $select.find(`option[value="${value}"]`).prop('selected', true);
    $select.trigger('change'); // Might trigger other listeners
}

// Setup event listeners
function initializeModeSwitch() {
    const $modeSwitchItems = $('[data-name="LabMode"]');
    if (debug) { console.log(`Found ${$modeSwitchItems.length} mode switch elements`); }

    $modeSwitchItems.each((index, element) => {
        element.addEventListener('change', () => { // Changed to 'change'
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
