/*
 * Script Name: NewStyles.js
 * Authors: Mark Morgan
 * Version: 2026.08.13.2226
 * Baseline Styling Code
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
    //if (debug) console.log(`[setColors] Starting`);

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

    //if (debug) console.log(`[setColors] Finished`);
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
            //if (debug) console.log(`[Observer] ${mutations.length} mutations → refreshing colors`);
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

// ────────────────────────────────────────────────
// Expandable Code Blocks
// Collapses long code blocks to a fixed number of visible lines,
// with a rotating triangle toggle + label in the .codeTitle bar (matches
// the existing <details>/blockquote expandable convention).
// ────────────────────────────────────────────────

function initExpandableCodeBlocks() {
    // === CONFIG ===
    const MAX_VISIBLE_LINES = 4; // number of lines shown before "expandable" kicks in
    // ==============

    if (debug) console.log(`[initExpandableCodeBlocks] Scanning for code blocks`);

    let processedCount = 0;
    let skippedCount = 0;

    document.querySelectorAll('pre').forEach(pre => {
        try {
            const code = pre.querySelector('code.prettyprinted, code.prettyprint');
            const codeTitle = pre.querySelector('.codeTitle');

            if (!code || !codeTitle) {
                skippedCount++;
                return;
            }

            if (pre.dataset.collapsibleInit) {
                return; // already processed
            }
            pre.dataset.collapsibleInit = 'true';

            pre.classList.add('collapsible-code');

            // Determine a tint (lighter or darker than the base background) so the
            // haze is visible even on a blank trailing line, not just matching text
            const bgRaw = getComputedStyle(code).backgroundColor;
            const rgbMatch = bgRaw.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);

            if (rgbMatch) {
                const r = parseInt(rgbMatch[1]);
                const g = parseInt(rgbMatch[2]);
                const b = parseInt(rgbMatch[3]);

                // Perceived luminance (0 = black, 1 = white)
                const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

                // Dark backgrounds get a light tint (lighten); light backgrounds get a dark tint (darken)
                const tint = luminance < 0.5 ? [255, 255, 255] : [0, 0, 0];

                pre.style.setProperty('--code-haze-r', tint[0]);
                pre.style.setProperty('--code-haze-g', tint[1]);
                pre.style.setProperty('--code-haze-b', tint[2]);

                if (debug) console.log(`[initExpandableCodeBlocks] bg luminance: ${luminance.toFixed(2)} → tint: rgb(${tint.join(',')})`);
            }

            // Group existing right-side items (Copy, Type text) into one wrapper,
            // so .codeTitle still only has 2 children and space-between still works
            const titleEl = codeTitle.querySelector('.title');
            let actionsWrapper = codeTitle.querySelector('.codeTitle-actions');

            if (!actionsWrapper) {
                actionsWrapper = document.createElement('span');
                actionsWrapper.className = 'codeTitle-actions';

                Array.from(codeTitle.children).forEach(child => {
                    if (child !== titleEl) {
                        actionsWrapper.appendChild(child);
                    }
                });

                codeTitle.appendChild(actionsWrapper);
            }

            // Toggle = label ("Show more"/"Show less") + rotating triangle arrow
            const toggle = document.createElement('span');
            toggle.className = 'code-expand-toggle';
            toggle.setAttribute('role', 'button');
            toggle.setAttribute('tabindex', '0');
            toggle.setAttribute('aria-expanded', 'false');
            toggle.setAttribute('aria-label', 'Show more of this code block');
            toggle.setAttribute('title', 'Show more of this code block');

            const toggleLabel = document.createElement('span');
            toggleLabel.className = 'code-expand-toggle-label';
            toggleLabel.textContent = 'Show more';

            const toggleArrow = document.createElement('span');
            toggleArrow.className = 'code-expand-toggle-arrow';

            toggle.appendChild(toggleLabel);
            toggle.appendChild(toggleArrow);
            actionsWrapper.appendChild(toggle);

            const checkOverflow = () => {
                const trueHeight = code.scrollHeight;
                if (trueHeight === 0) return; // still hidden (e.g. collapsed accordion) — recheck later

                const lineHeight = parseFloat(getComputedStyle(code).lineHeight)
                    || (parseFloat(getComputedStyle(code).fontSize) * 1.2);
                const maxHeight = lineHeight * MAX_VISIBLE_LINES;
                pre.style.setProperty('--collapsed-max-height', `${maxHeight}px`);

                // Round to nearest whole line to avoid sub-pixel rounding false positives —
                // only expand if content actually reaches into the line AFTER MAX_VISIBLE_LINES
                const actualLineCount = Math.round(trueHeight / lineHeight);

                if (actualLineCount > MAX_VISIBLE_LINES) {
                    pre.classList.add('collapsible-active');
                    toggle.style.display = 'inline-flex';
                } else {
                    pre.classList.remove('collapsible-active');
                    toggle.style.display = 'none';
                }
            };

            const toggleExpanded = () => {
                const expanded = pre.classList.toggle('expanded');
                toggle.classList.toggle('expanded', expanded);
                toggleLabel.textContent = expanded ? 'Show less' : 'Show more';
                const aria = expanded ? 'Show less of this code block' : 'Show more of this code block';
                toggle.setAttribute('aria-expanded', String(expanded));
                toggle.setAttribute('aria-label', aria);
                toggle.setAttribute('title', aria);
                if (debug) console.log(`[initExpandableCodeBlocks] Toggled → expanded: ${expanded}`);
            };

            toggle.addEventListener('click', toggleExpanded);
            toggle.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    toggleExpanded();
                }
            });

            // Re-check whenever this element becomes visible (e.g. accordion/tab opens)
            const observer = new IntersectionObserver(entries => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) checkOverflow();
                });
            }, { threshold: 0.01 });
            observer.observe(pre);

            checkOverflow(); // also try immediately, in case already visible
            window.addEventListener('resize', checkOverflow);

            processedCount++;
        } catch (err) {
            if (debug) console.error(`[initExpandableCodeBlocks] Failed on a code block: ${err.message}`);
        }
    });

    if (debug) console.log(`[initExpandableCodeBlocks] Done. Processed: ${processedCount}, Skipped: ${skippedCount}`);
}

// Initial run
try {
    if (debug) console.log(`Initial initExpandableCodeBlocks()`);
    initExpandableCodeBlocks();
} catch (err) {
    if (debug) console.error(`Initial initExpandableCodeBlocks failed: ${err.message}`);
}

// Observer setup (delayed) — re-scan for late-loaded / accordion-revealed code blocks
setTimeout(() => {
    if (debug) console.log(`Setting up MutationObserver for expandable code blocks`);
    try {
        const codeBlockObserver = new MutationObserver((mutations) => {
            initExpandableCodeBlocks();
        });

        codeBlockObserver.observe(document.body, { childList: true, subtree: true });
        if (debug) console.log(`Observer attached for expandable code blocks (document.body)`);
    } catch (err) {
        if (debug) console.error(`Expandable code block observer setup failed: ${err.message}`);
    }
}, 2000);

// End - Expandable Code Blocks
