/*
 * Script Name: LabModeSwitch.js
 * Authors: Mark Morgan, Grok 3 (xAI)
 * Version: 1.0
 * Date: March 08, 2025
 * Description: Creates a custom dropdown to replace the original difficulty button, 
 *              managing mode switching with a styled div-based UI.
 */

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

    // Create custom dropdown structure
    const $dropdown = $('<div class="select-Difficulty" data-name="select-Difficulty"></div>');
    const $selected = $('<span class="selected"></span>').text(defaultValue);
    const $optionsList = $('<ul class="options"></ul>').hide(); // Hidden by default
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

    // Add options to the list
    availableOptions.forEach(option => {
        const $li = $(`<li>${option.text}</li>`);
        $li.on('click', () => {
            $selected.text(option.text);
            $optionsList.hide(); // Ensure list hides after selection
            $dropdown.addClass('selected'); // Mark as selected for arrow
            handleSelection(option.text);
            if (debug) { console.log(`Selected ${option.text} from custom dropdown, options hidden`); }
        });
        $optionsList.append($li);
    });

    // Assemble dropdown
    $dropdown.append($selected).append($optionsList);

    // Toggle dropdown on click
    $dropdown.on('click', (e) => {
        e.stopPropagation(); // Prevent closing immediately
        $optionsList.toggle();
        if (debug) { console.log(`Dropdown toggled, options ${$optionsList.is(':visible') ? 'visible' : 'hidden'}`); }
    });

    // Close dropdown when clicking outside
    $(document).on('click', () => {
        $optionsList.hide();
        if (debug) { console.log("Clicked outside, options hidden"); }
    });

    // Place inside the same parent <p> as the original
    const $parentP = difficultyButton.closest('p');
    if ($parentP.length) {
        $parentP.append($dropdown);
        if (debug) { console.log("Placed select-Difficulty inside parent <p>"); }
    } else {
        if (debug) { console.log("No parent <p> found, appending after difficultyButton"); }
        difficultyButton.after($dropdown); // Fallback
    }

    // Apply 'selected' class if default value is a valid mode
    if (defaultValue.toLowerCase() in modes) {
        $dropdown.addClass('selected');
        if (debug) { console.log("Applied 'selected' class for initial value"); }
    }

    if (debug) { console.log(`Created select-Difficulty dropdown with default: ${defaultValue}`); }

    // Handle selection logic
    function handleSelection(selectedMode) {
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
    }

    // Apply initial mode settings
    const initialMode = defaultValue;
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
}

// Initialize the Mode Switch
try {
    createCustomDifficultyDropdown();
} catch (err) {
    console.error("select-Difficulty dropdown initialization failed:", err);
}
