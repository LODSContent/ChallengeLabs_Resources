/*
 * Script Name: LabModeSwitch.js
 * Authors: Mark Morgan, Grok 3 (xAI)
 * Version: 1.16
 * Date: March 09, 2025
 * Description: Creates a custom dropdown to replace the original difficulty button, 
 *              managing mode switching with a styled div-based UI.
 */

// Code for mode switching
const showLabMode = $(`select[data-name="ShowLabMode"]`).val()?.toLowerCase() || null;

// Define modes globally
const modes = {
    guided: { 
        ShowGuided: 'Yes', 
        ShowAdvanced: 'Yes', 
        ShowActivity: 'Yes'
    },
    advanced: { 
        ShowGuided: 'No', 
        ShowAdvanced: 'Yes', 
        ShowActivity: 'Yes' 
    },
    expert: { 
        ShowGuided: 'No', 
        ShowAdvanced: 'No', 
        ShowActivity: 'No' 
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
    const $selected = $(`<span class="selected">${defaultValue}</span>`); // Initial span
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
        $li.on('click', (e) => {
            e.stopPropagation(); // Prevent bubbling to dropdown
            // Replace old selected span with a new one
            $selected.remove(); // Remove old span
            const $newSelected = $(`<span class="selected">${option.text}</span>`);
            $dropdown.prepend($newSelected); // Add new span at the top
            $optionsList.hide(); // Hide list after selection
            $dropdown.removeClass('expanded').addClass('selected'); // Switch to selected state
            handleSelection(option.text);
            if (debug) { console.log(`Selected ${option.text} from custom dropdown, options hidden`); }
        });
        $optionsList
