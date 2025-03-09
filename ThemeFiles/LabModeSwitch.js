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

// Helper Functions
function setSelectValue(name, value) {
    const $select = $(`select[data-name="${name}"]`);
    $select.find(`option[value="${value}"]`).prop('selected', true);
    $select.trigger('change');
}

// Create and manage custom difficulty dropdown
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
    const $newSelect = $('<select class="select-Difficulty" data-name="select-Difficulty"></select>');
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

    // Get computed styles from original element (matches .instructions #page0 div.difficultybutton)
    const originalStyles = window.getComputedStyle(difficultyButton[0]);
    const backgroundColor = originalStyles.backgroundColor;
    const fontFamily = originalStyles.fontFamily;
    const fontSize = originalStyles.fontSize;
    const textColor = originalStyles.color;

    // Add options to dropdown with matching background
    availableOptions.forEach(option => {
        const $option = $(`<option value="${option.value}">${option.text}</option>`);
        if (option.text === defaultValue) {
            $option.prop('selected', true);
        }
        $option.css('background-color', backgroundColor); // Match option background
        $newSelect.append($option);
    });

    // Apply styles to new dropdown
    $newSelect.css({
        'background-color': backgroundColor,
        'font-family': fontFamily,
        'font-size': fontSize,
        'color': textColor,
        'border': 'none'
    });
    if (debug) { console.log(`Applied styles to select-Difficulty: background-color=${backgroundColor}, font-family=${fontFamily}, font-size=${fontSize}, color=${textColor}, border=none`); }

    // Place inside the same parent <p> as the original
    const $parentP = difficultyButton.closest('p');
    if ($parentP.length) {
        $parentP.append($newSelect);
        if (debug) { console.log("Placed select-Difficulty inside parent <p>"); }
    } else {
        if (debug) { console.log("No parent <p> found, appending after difficultyButton"); }
        difficultyButton.after($newSelect); // Fallback
    }

    if (debug) { console.log(`Created select-Difficulty dropdown with default: ${defaultValue}`); }

    // Apply initial mode settings based on default value
    const initialMode = $newSelect.val();
    const initialModeKey = initialMode.toLowerCase();
    if (initialModeKey in modes) {
        const settings = modes[initialModeKey];
        for (const [name, value] of Object.entries(settings)) {
            if (typeof value === 'function') {
                value();
            } else {
                setSelectValue(name, value);
            }
        }
        if (debug) { console.log(`Applied initial ${initialMode} mode settings from select-Difficulty`); }
    }

    // Event listener for new dropdown
    $newSelect.on('change', () => {
        const selectedMode = $newSelect.val();
        if (debug) { console.log(`select-Difficulty dropdown changed to: ${selectedMode}`); }
        
        // Update original button’s innerHTML (hidden but tracked)
        if (difficultyButton.length) {
            difficultyButton.each((index, element) => {
                element.innerHTML = selectedMode;
            });
            if (debug) { console.log(`Updated difficultybutton [data-name="Difficulty"] innerHTML to: ${selectedMode}`); }
        }

        // Apply mode settings
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
            if (debug) { console.log(`Applied ${selectedMode} mode settings from select-Difficulty`); }
        }
    });
}

// Initialize the Mode Switch
try {
    createCustomDifficultyDropdown();
} catch (err) {
    console.error("select-Difficulty dropdown initialization failed:", err);
}
