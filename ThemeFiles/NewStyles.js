// Begin Blockquote styling code (Matching alternate icons to platform icons.)

/*
 * Script Name: NewStyles.js
 * Authors: Mark Morgan
 * Version: 2026.03.05.1832
*/

// Helper Functions
function getLabVariable(name) {
    if (debug) { console.log(`[getLabVariable] Called for: ${name}`); }
    try {
        if (debug) { console.log(`Retrieving lab variable - ${name}`); }
        let clientAPI = null;
        try {
            clientAPI = window.api.v1;
            if (debug) { console.log(`API object found: window.api.v1`); }
        } catch(e) {
            if (debug) { console.log(`No window.api.v1 available (${e.message})`); }
        }

        if (clientAPI) {
            if (debug) { console.log(`Using API method to get lab variable ${name}`); }
            let value = window.api.v1.getLabVariable(name)?.toLowerCase() || null;
            if (debug) { console.log(`API returned: ${name} = ${value}`); }
            return value;
        } else {
            if (debug) { console.log(`Falling back to DOM lookup for ${name}`); }
            let checkName = name.toLowerCase();
            let $input = $('[data-name]').filter(function() { 
                return $(this).attr('data-name')?.toLowerCase() === checkName; 
            });
            let value = $input.val()?.toLowerCase() || null;
            if (debug) { 
                console.log(`DOM lookup result: ${name} = ${value} (found ${$input.length} elements)`); 
            }
            return value;
        }
    } catch (e) {
        if (debug) { console.log(`[getLabVariable] Failed for ${name}: ${e.message}`); }
        return null;
    }
}

function setLabVariable(name, value) {
    if (debug) { console.log(`[setLabVariable] ${name} ← ${value}`); }
    try {
        let clientAPI = null;
        try {
            clientAPI = window.api.v1;
        } catch(e) {}

        if (clientAPI) {
            if (debug) { console.log(`Setting via API: ${name} = ${value}`); }
            window.api.v1.setLabVariable(name, value);
        } else {
            if (debug) { console.log(`Setting via DOM: [data-name="${name}"]`); }
            $(`[data-name="${name}"]`).val(value).trigger("change");
        }
    } catch (e) {
        if (debug) { console.log(`[setLabVariable] Failed for ${name}: ${e.message}`); }
    }
}

// Initialize the debug variable from the lab variable
debug = ["true", "yes"].includes(
    (getLabVariable("Debug") ?? getLabVariable("debug") ?? "").trim().toLowerCase()
);
if (debug) { 
    console.log(`%cDebug mode ENABLED`, "color:#0f0; font-weight:bold");
    console.log(`Loading the NewStyles.js code.`); 
} else {
    console.log(`Debug mode is OFF`);
}

// ────────────────────────────────────────────────

function get_style_rule_value(selector, style, match) {
    if (debug) { console.log(`[get_style_rule_value] Looking for ${selector} → ${style} (${match})`); }
    for (var i = 0; i < document.styleSheets.length; i++) {
        var mysheet = document.styleSheets[i];
        try {
            var myrules = mysheet.cssRules ? mysheet.cssRules : mysheet.rules;
            for (var j = 0; j < myrules.length; j++) {
                if (!myrules[j].selectorText) continue;

                let matched = false;
                if (match === 'exact') {
                    matched = myrules[j].selectorText.toLowerCase() === selector;
                } else {
                    matched = myrules[j].selectorText.toLowerCase().includes(selector);
                }

                if (matched && myrules[j].style[style] !== undefined) {
                    let value = myrules[j].style[style];
                    if (debug) { 
                        console.log(`  Found in sheet ${i}, rule ${j}: ${value}`); 
                    }
                    return value;
                }
            }
        } catch (e) {
            if (debug) { console.log(`  Sheet ${i} inaccessible (${e.message})`); }
        }
    }
    if (debug) { console.log(`  → No match found for ${selector} ${style}`); }
    return undefined;
}

// ────────────────────────────────────────────────

function convertRGB(rgbColor) {
    if (!rgbColor) {
        if (debug) { console.log(`[convertRGB] No color provided`); }
        return undefined;
    }
    try {
        if (debug) { console.log(`[convertRGB] Converting: ${rgbColor}`); }
        var a = rgbColor.split("(")[1]?.split(")")[0];
        if (!a) throw new Error("Invalid rgb format");
        var parts = a.split(",").map(x => parseInt(x.trim()));
        var hex = parts.map(x => {
            let h = x.toString(16);
            return h.length === 1 ? "0" + h : h;
        }).join("");
        let result = "#" + hex;
        if (debug) { console.log(`  → ${result}`); }
        return result;
    } catch (e) {
        if (debug) { console.log(`[convertRGB] Failed: ${e.message}`); }
        return undefined;
    }
}

// ────────────────────────────────────────────────

function setColors() {
    if (debug) { console.log(`[setColors] Starting color collection & variable update`); }

    const root = document.querySelector(':root');
    if (!root) {
        if (debug) { console.warn(`[setColors] :root not found`); }
        return;
    }

    // Read control variables
    const blockquoteBackgroundEnable = getComputedStyle(document.body).getPropertyValue('--blockquote-background-enable').trim() || 'false';
    const blockquoteBackgroundAlpha   = getComputedStyle(document.body).getPropertyValue('--blockquote-background-alpha').trim()  || '10';
    const blockquoteShadowEnable      = getComputedStyle(document.body).getPropertyValue('--blockquote-shadow-enable').trim()     || 'false';
    const blockquoteShadowColor       = getComputedStyle(document.body).getPropertyValue('--blockquote-shadow-color').trim()      || '#000000';

    if (debug) {
        console.log(`  Controls: bgEnable=${blockquoteBackgroundEnable}, alpha=${blockquoteBackgroundAlpha}, shadowEnable=${blockquoteShadowEnable}`);
    }

    const icons = ["alert", "help", "hint", "note"];
    icons.forEach(icon => {
        if (debug) { console.log(`  Processing icon: ${icon}`); }
        let color = get_style_rule_value(`blockquote.${icon}`, 'border-color', 'exact');
        color = convertRGB(color);

        if (color) {
            root.style.setProperty(`--${icon}-color`, color);

            let bgValue;
            if (blockquoteBackgroundEnable === 'true') {
                bgValue = color + blockquoteBackgroundAlpha;
            } else if (blockquoteBackgroundEnable === 'false') {
                bgValue = 'transparent';
            } else {
                bgValue = blockquoteBackgroundEnable;
            }
            root.style.setProperty(`--${icon}-bg-color`, bgValue);

            // Shadow
            const shouldHaveShadow = blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes(icon);
            root.style.setProperty(`--${icon}-shadow`, shouldHaveShadow ? blockquoteShadowColor : 'none');
        }
    });

    // ── knowledge ───────────────────────────────────────
    let color = get_style_rule_value('.primary-color', 'color', 'partial');
    color = convertRGB(color);
    if (color) {
        root.style.setProperty('--knowledge-color', color);
        let bg = blockquoteBackgroundEnable === 'true' 
            ? color + blockquoteBackgroundAlpha 
            : (blockquoteBackgroundEnable === 'false' ? 'transparent' : blockquoteBackgroundEnable);
        root.style.setProperty('--knowledge-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('knowledge'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--knowledge-shadow', shadow);
    }

    // ── standard blockquote ─────────────────────────────
    color = get_style_rule_value('.accent-border', 'border-color', 'partial');
    let bgColor = get_style_rule_value('.accent-background', 'background-color', 'partial');
    color = convertRGB(color);
    bgColor = convertRGB(bgColor);

    if (color) {
        root.style.setProperty('--blockquote-color', color);
        let bg = blockquoteBackgroundEnable === 'true' 
            ? color + blockquoteBackgroundAlpha 
            : (blockquoteBackgroundEnable === 'false' ? (bgColor || 'transparent') : blockquoteBackgroundEnable);
        root.style.setProperty('--blockquote-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('blockquote'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--blockquote-shadow', shadow);
    }

    // ── expandable blockquote ───────────────────────────
    color = get_style_rule_value('.primary-color', 'color', 'partial');
    color = convertRGB(color);
    if (color) {
        root.style.setProperty('--expandable-blockquote-color', color);
        let bg = blockquoteBackgroundEnable === 'true' 
            ? color + blockquoteBackgroundAlpha 
            : (blockquoteBackgroundEnable === 'false' ? 'transparent' : blockquoteBackgroundEnable);
        root.style.setProperty('--expandable-blockquote-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('expandable-blockquote'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--expandable-blockquote-shadow', shadow);
    }

    // ── button primary ──────────────────────────────────
    color = get_style_rule_value('button.primary', 'background-color', 'partial');
    color = convertRGB(color);
    if (color) {
        root.style.setProperty('--button-primary-color', color);
    }

    if (debug) { console.log(`[setColors] Completed`); }
}

// ────────────────────────────────────────────────

try {
    if (debug) { console.log(`Initial call to setColors()`); }
    setColors();
} catch (err) {
    if (debug) { console.error(`Initial setColors failed: ${err.message}`); }
}

// Timeout for creating the observer
setTimeout(() => {
    if (debug) { console.log(`Setting up MutationObserver for #settings-menu`); }
    try {
        const observer = new MutationObserver((mutations) => {
            if (debug) { console.log(`[Observer] Detected ${mutations.length} mutations`); }
            setColors();
        });
        const target = document.getElementById('settings-menu');
        if (target) {
            observer.observe(target, { attributes: true });
            if (debug) { console.log(`Observer attached to #settings-menu`); }
        } else {
            if (debug) { console.warn(`#settings-menu not found → observer not attached`); }
        }
    } catch (err) {
        if (debug) { console.error(`Observer setup failed: ${err.message}`); }
    }
}, 2000);

// End - Blockquote styling code
