/*
 * Script Name: ToggleHandler.js
 * Authors: John Rice, Mark Morgan
 * Version: 1.10
 * Date: March 08, 2025
 * Description: Translates elements in the HTML to the target language.
 */

function handleToggles() {
    // Fetch toggle settings with defaults
    const showToggle = getToggleValue('ShowToggle');
    const showHints = getToggleValue('ShowHints');
    const showGuided = getToggleValue('ShowGuided');
    const showAdvanced = getToggleValue('ShowAdvanced');
    if (debug) { console.log(`Toggle settings - ShowToggle: ${showToggle}, ShowHints: ${showHints}, ShowGuided: ${showGuided}, ShowAdvanced: ${showAdvanced}`); }

    const $checkMode = $('input.checkMode');
    const $hintsElements = $('.hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced');

    // Handle ShowHints
    if (!showHints || showHints !== 'no') {
        if (debug) { console.log("Hints enabled by default or set to yes"); }
        $checkMode.prop('checked', true);
        if (showToggle === 'yes') {
            setSelectValue('ShowGuided', showGuided, 'Yes');
            setSelectValue('ShowAdvanced', showAdvanced, 'Yes');
        }
    } else {
        if (debug) { console.log("Hints disabled (ShowHints = no)"); }
        $checkMode.prop('checked', false);
        $hintsElements.hide();
        if (showToggle === 'yes') {
            setSelectValue('ShowGuided', showGuided, 'No');
            setSelectValue('ShowAdvanced', showAdvanced, 'No');
        }
    }

    // Handle ShowToggle
    if (showToggle === 'no') {
        if (debug) { console.log("Removing hint toggles (ShowToggle = no)"); }
        $('.hint-toggle, [data-name="ShowHints"]').remove();
    } else {
        if (debug) { console.log("Setting up toggle event listener (ShowToggle = yes or null)"); }
        $('body').on('click', 'input.checkMode', function () {
            const isChecked = $(this).is(':checked');
            if (debug) { console.log(`Checkbox toggled: ${isChecked ? 'checked' : 'unchecked'}`); }

            if (isChecked) {
                $checkMode.prop('checked', true);
                $hintsElements.show();
                if (!isEditor()) {
                    setSelectValue('ShowHints', 'yes', 'Yes');
                    if (showToggle === 'yes') {
                        setSelectValue('ShowGuided', showGuided, 'Yes');
                        setSelectValue('ShowAdvanced', showAdvanced, 'Yes');
                    }
                }
            } else {
                $hintsElements.hide();
                $('[data-variable-name="ShowGuided"], [data-variable-name="ShowAdvanced"]').hide();
                $checkMode.prop('checked', false);
                if (!isEditor()) {
                    setSelectValue('ShowHints', 'no', 'No');
                    if (showToggle === 'yes') {
                        setSelectValue('ShowGuided', showGuided, 'No');
                        setSelectValue('ShowAdvanced', showAdvanced, 'No');
                    }
                }
            }
        });
    }

    // Helper Functions
    function getToggleValue(name) {
        return window.api.v1.getLabVariable(name).val()?.toLowerCase() || null;
    }

    function setSelectValue(name, condition, value) {
        if (condition === 'yes') {
            window.api.v1.setLabVariable(name,value);
        }
    }

    function isEditor() {
        return document.querySelector('link[href^="/Css/EditInstructions.css"]') !== null;
    }
}

// Execute immediately (timeout removed, add back if needed)
handleToggles();
