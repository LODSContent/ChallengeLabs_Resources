/*
 * Script Name: LabModeSwitch.js
 * Authors: Mark Morgan
 * Version: 1.17
 * Date: March 09, 2025
 * Description: Creates a custom dropdown to replace the original difficulty button, 
 *              managing mode switching with a styled div-based UI.
 */

// Code for mode switching
const showLabMode = $(`select[data-name="ShowLabMode"]`).val()?.toLowerCase() || null;

// Define modes globally
const modes = {
    learn: { 
        ShowLearn: 'Yes',
        ShowGuided: 'Yes', 
        ShowAdvanced: 'Yes',
        ShowMCQ: 'Yes',
        ShowActivity: 'No'
    },
    guided: { 
        ShowLearn: 'No',        
        ShowGuided: 'Yes', 
        ShowAdvanced: 'Yes',
        ShowMCQ: 'No',
        ShowActivity: 'Yes'
    },
    advanced: { 
        ShowLearn: 'No',        
        ShowGuided: 'No', 
        ShowAdvanced: 'Yes', 
        ShowMCQ: 'No',        
        ShowActivity: 'Yes' 
    },
    expert: { 
        ShowLearn: 'No',        
        ShowGuided: 'No', 
        ShowAdvanced: 'No', 
        ShowMCQ: 'No',        
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

    let defaultValue = difficultyButton[0].innerHTML.trim(); // Get original innerHTML
    let initialMode = defaultValue;
    if (debug) { console.log(`Original difficulty button value: ${defaultValue}`); }

    // If Expert, skip and leave original
    if (defaultValue.toLowerCase() === 'expert') {
        if (debug) { console.log("Default value is Expert, retaining original difficulty button"); }
        return;
    }

    // Setting default to Select Lab Mode if not expert
    defaultValue = "Select lab mode"

    // Hide original button
    difficultyButton.hide();
    if (debug) { console.log("Hid original difficultybutton [data-name=\"Difficulty\"]"); }

    // Create custom dropdown structure
    const $dropdown = $('<div class="select-Difficulty" data-name="select-Difficulty"></div>');
    const $optionsList = $('<ul class="options"></ul>').hide(); // Hidden by default
    const options = [
        { text: 'Learn', value: 'Learn' },        
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

    // Add initial selected span
    $dropdown.append($(`<span class="selected">${defaultValue}</span>`));

    // Add options to the list
    availableOptions.forEach(option => {
        const $li = $(`<li>${option.text}</li>`);
        $li.on('click', (e) => {
            e.stopPropagation(); // Prevent bubbling to dropdown
            // Remove current selected span and add new one
            $dropdown.find('.selected').remove(); // Remove existing .selected
            const $newSelected = $(`<span class="selected">${option.text}</span>`);
            $dropdown.prepend($newSelected); // Add new span at the top
            $optionsList.hide(); // Hide list after selection
            $dropdown.removeClass('expanded').addClass('selected'); // Switch to selected state
            handleSelection(option.text);
            if (debug) { console.log(`Selected ${option.text} from custom dropdown, options hidden`); }
        });
        $optionsList.append($li);
    });

    // Assemble dropdown
    $dropdown.append($optionsList);

    // Function to handle outside clicks
    const outsideClickHandler = (e) => {
        if (!$dropdown.is(e.target) && !$dropdown.has(e.target).length) {
            $optionsList.hide();
            $dropdown.removeClass('expanded');
            if (debug) { console.log("Clicked outside, options hidden, state reset to default or selected"); }
        }
    };

    // Toggle dropdown on click
    $dropdown.on('click', (e) => {
        e.stopPropagation(); // Prevent closing immediately
        if ($optionsList.is(':visible')) {
            $dropdown.removeClass('expanded');
            $(document).off('click', outsideClickHandler); // Remove handler when closing
        } else {
            $dropdown.addClass('expanded');
            $(document).on('click', outsideClickHandler); // Add handler when opening
        }
        $optionsList.toggle();
        if (debug) { console.log(`Dropdown toggled, options ${$optionsList.is(':visible') ? 'visible' : 'hidden'}, state: ${$dropdown.hasClass('expanded') ? 'expanded' : $dropdown.hasClass('selected') ? 'selected' : 'default'}`); }
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

    // Apply initial mode settings (no .selected class yet)
    //const initialMode = defaultValue;
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

    // Hide .hint-toggle if it exists, whenever dropdown is created
    const $hintToggle = $('.hint-toggle');
    if ($hintToggle.length) {
        $hintToggle.hide();
        if (debug) { console.log("Hid .hint-toggle element(s)"); }
    }
}

// Initialize the Mode Switch
if (showLabMode == 'yes') {
    if (debug) { console.log(`ShowLabMode is on. Initializing Mode Switch.`); }
    try {
        createCustomDifficultyDropdown();
    } catch (err) {
        console.error("select-Difficulty dropdown initialization failed:", err);
    }
} else {
    if (debug) { console.log(`ShowLabMode is off. Skipping Mode Switch initialization.`); }
}
