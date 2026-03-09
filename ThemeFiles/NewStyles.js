/*
 * Script Name: NewStyles.js
 * Authors: Mark Morgan
 * Version: 2026.03.05.1832
 * Blockquote styling code
*/

// Helper Functions
function getLabVariable(name) {
    if (debug) { console.log(`[getLabVariable] Called for: ${name}`); }
    try {
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

// Initialize debug from lab variable
debug = "false";
//debug = ["true", "yes"].includes(
//    (getLabVariable("Debug") ?? getLabVariable("debug") ?? "").trim().toLowerCase()
//);
if (debug) { 
    console.log(`%cDebug mode ENABLED`, "color:#0f0; font-weight:bold");
    console.log(`Loading the NewStyles.js code.`); 
} else {
    console.log(`Debug mode is OFF`);
}

// ────────────────────────────────────────────────
// Helper: Get resolved (computed) color value from an element
function getComputedColor(selector, property = 'color', fallbackSelector = null) {
    if (debug) {
        //console.log(`[getComputedColor] Resolving ${property} for selector: ${selector}`);
    }

    let element = document.querySelector(selector);

    if (!element && fallbackSelector) {
        element = document.querySelector(fallbackSelector);
        if (debug && element) console.log(`  → fell back to ${fallbackSelector}`);
    }

    if (!element) {
        element = document.documentElement; // :root
        if (debug) console.log(`  → no match, using :root`);
    }

    try {
        const computed = getComputedStyle(element);
        let raw;

        if (property.includes('border')) {
            raw = computed.borderColor;
        } else if (property.includes('background')) {
            raw = computed.backgroundColor;
        } else {
            raw = computed.color;
        }

        //if (debug) console.log(`  Computed raw: ${raw}`);

        // Normalize "rgb(r g b)" → "rgb(r, g, b)" (some browsers omit commas)
        if (raw && raw.includes('rgb') && !raw.includes(',')) {
            raw = raw.replace(/rgb\((\d+)\s+(\d+)\s+(\d+)\)/, 'rgb($1, $2, $3)');
        }

        const hex = convertRGB(raw);
        if (hex) return hex;

        if (debug) console.log(`  → convertRGB failed on: ${raw}`);
    } catch (err) {
        if (debug) console.warn(`[getComputedColor] Failed for ${selector}: ${err.message}`);
    }

    return undefined;
}

// ────────────────────────────────────────────────
// Safe RGB → Hex converter (handles rgb(...), skips vars)
function convertRGB(input) {
    if (!input) {
        //if (debug) console.log(`[convertRGB] No input`);
        return undefined;
    }

    const str = input.trim();

    if (str.startsWith('var(')) {
        //if (debug) console.log(`[convertRGB] CSS var detected (should not reach here): ${str}`);
        return undefined;
    }

    if (!str.startsWith('rgb')) {
        //if (debug) console.log(`[convertRGB] Not rgb(): ${str}`);
        return undefined;
    }

    try {
        //if (debug) console.log(`[convertRGB] Converting: ${str}`);

        let valuesStr = str.split('(')[1]?.split(')')[0];
        if (!valuesStr) throw new Error("Invalid rgb format");

        let parts = valuesStr.split(',').map(x => parseInt(x.trim(), 10));
        if (parts.length < 3 || parts.some(isNaN)) {
            throw new Error("Invalid components");
        }

        // Take only RGB, ignore alpha
        let [r, g, b] = parts;

        let hex = [r, g, b].map(x => {
            let h = Math.max(0, Math.min(255, x)).toString(16);
            return h.length === 1 ? '0' + h : h;
        }).join('');

        const result = '#' + hex.toUpperCase();
        //if (debug) console.log(`  → ${result}`);
        return result;
    } catch (e) {;
        if (debug) console.log(`[convertRGB] Failed: ${e.message} (input: ${str})`);
        return undefined;
    }
}

// ────────────────────────────────────────────────
function setColors() {
    if (debug) console.log(`[setColors] Starting`);

    const root = document.querySelector(':root');
    if (!root) {
        if (debug) console.warn(`:root not found`);
        return;
    }

    // Read control variables (from computed style on body/:root)
    const styles = getComputedStyle(document.body);
    const blockquoteBackgroundEnable = (styles.getPropertyValue('--blockquote-background-enable') || 'false').trim();
    const blockquoteBackgroundAlpha   = (styles.getPropertyValue('--blockquote-background-alpha')  || '10').trim();
    const blockquoteShadowEnable      = (styles.getPropertyValue('--blockquote-shadow-enable')     || 'false').trim();
    const blockquoteShadowColor       = (styles.getPropertyValue('--blockquote-shadow-color')      || '#000000').trim();

    if (debug) {
        //console.log(`  Controls → bgEnable: ${blockquoteBackgroundEnable}, alpha: ${blockquoteBackgroundAlpha}, shadowEnable: ${blockquoteShadowEnable}`);
    }

    const icons = ["alert", "help", "hint", "note"];
    icons.forEach(icon => {
        //if (debug) console.log(`  → ${icon}`);

        // Prefer existing blockquote element if available
        let color = getComputedColor(`blockquote.${icon}`, 'border-color');

        // Fallback if no such element exists yet
        if (!color) {
            color = getComputedColor(`.${icon}-color`, 'color', ':root');
        }

        if (color) {
            root.style.setProperty(`--${icon}-color`, color);

            let bgValue;
            if (blockquoteBackgroundEnable === 'true') {
                const alpha = blockquoteBackgroundAlpha.padStart(2, '0');
                bgValue = color + alpha;   // e.g. #ff00001a
            } else if (blockquoteBackgroundEnable === 'false') {
                bgValue = 'transparent';
            } else {
                bgValue = blockquoteBackgroundEnable;
            }
            root.style.setProperty(`--${icon}-bg-color`, bgValue);

            const shouldShadow = blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes(icon);
            root.style.setProperty(`--${icon}-shadow`, shouldShadow ? blockquoteShadowColor : 'none');
        } else if (debug) {
            console.warn(`    Could not resolve color for ${icon}`);
        }
    });

    // ── Knowledge / primary-color based ────────────────────────────────
    let primaryColor = getComputedColor('.primary-color', 'color', ':root');
    if (primaryColor) {
        root.style.setProperty('--knowledge-color', primaryColor);

        let bg = blockquoteBackgroundEnable === 'true'
            ? primaryColor + blockquoteBackgroundAlpha.padStart(2, '0')
            : (blockquoteBackgroundEnable === 'false' ? 'transparent' : blockquoteBackgroundEnable);

        root.style.setProperty('--knowledge-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('knowledge'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--knowledge-shadow', shadow);
    }

    // ── Standard blockquote (accent) ───────────────────────────────────
    let accentBorderColor = getComputedColor('.accent-border', 'border-color', ':root');
    let accentBgColor     = getComputedColor('.accent-background', 'background-color', ':root');

    if (accentBorderColor) {
        root.style.setProperty('--blockquote-color', accentBorderColor);

        let bg = blockquoteBackgroundEnable === 'true'
            ? accentBorderColor + blockquoteBackgroundAlpha.padStart(2, '0')
            : (blockquoteBackgroundEnable === 'false'
                ? (accentBgColor || 'transparent')
                : blockquoteBackgroundEnable);

        root.style.setProperty('--blockquote-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('blockquote'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--blockquote-shadow', shadow);
    }

    // ── Expandable blockquote ──────────────────────────────────────────
    let expandableColor = getComputedColor('.primary-color', 'color', ':root'); // reuse primary
    if (expandableColor) {
        root.style.setProperty('--expandable-blockquote-color', expandableColor);

        let bg = blockquoteBackgroundEnable === 'true'
            ? expandableColor + blockquoteBackgroundAlpha.padStart(2, '0')
            : (blockquoteBackgroundEnable === 'false' ? 'transparent' : blockquoteBackgroundEnable);

        root.style.setProperty('--expandable-blockquote-bg-color', bg);

        const shadow = (blockquoteShadowEnable === 'true' || blockquoteShadowEnable.includes('expandable-blockquote'))
            ? blockquoteShadowColor : 'none';
        root.style.setProperty('--expandable-blockquote-shadow', shadow);
    }

    // ── Button primary ─────────────────────────────────────────────────
    let buttonColor = getComputedColor('button.primary', 'background-color', ':root');
    if (buttonColor) {
        root.style.setProperty('--button-primary-color', buttonColor);
    }

    if (debug) console.log(`[setColors] Finished`);
}

// ────────────────────────────────────────────────
// Initial run
try {
    if (debug) console.log(`Initial setColors()`);
    setColors();
} catch (err) {
    if (debug) console.error(`Initial setColors failed: ${err.message}`);
}

// Observer setup (delayed)
setTimeout(() => {
    if (debug) console.log(`Setting up MutationObserver on #settings-menu`);
    try {
        const observer = new MutationObserver((mutations) => {
            if (debug) console.log(`[Observer] ${mutations.length} mutations → refreshing colors`);
            setColors();
        });

        const target = document.getElementById('settings-menu');
        if (target) {
            observer.observe(target, { attributes: true });
            if (debug) console.log(`Observer attached to #settings-menu`);
        } else {
            if (debug) console.warn(`#settings-menu not found → no observer`);
        }
    } catch (err) {
        if (debug) console.error(`Observer setup failed: ${err.message}`);
    }
}, 2000);

// End - Blockquote styling code
