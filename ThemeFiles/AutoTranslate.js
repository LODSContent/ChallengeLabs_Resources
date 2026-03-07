/*
 * Script Name: AutoTranslate.js
 * Authors: Mark Morgan
 * Version: 2026.03.07.0047 (enhanced dynamic observer + debug for mutations)
 * Description: Translates lab content. Uses .instructions / .end-of-lab-report in auto mode;
 *              #labClient when language manually selected. Catches dynamic additions.
 */

// ... (keep your helper functions getLabVariable / setLabVariable unchanged)

// Initialize debug early
let debug = "false";
debug = ["true", "yes"].includes(
    (getLabVariable("Debug") ?? getLabVariable("debug") ?? "").trim().toLowerCase()
);

const autoTranslate = getLabVariable("AutoTranslate");
if (debug) console.log(`AutoTranslate setting: ${autoTranslate}`);

if (autoTranslate === 'no') {
    if (debug) console.log("Skipping Translation.");
} else {
    if (debug) console.log("Starting Translation.");

    const translatedElements = new Set();
    const findElements = 'blockquote, table, a, p, h1, h2, h3, h4, ol, ul, li, details, span, input[type="button"], #labNotificationsHeader';
    const elementArray = findElements.replace('[type="button"]', '').split(',').map(s => s.trim().toLowerCase());
    const ignoreElements = 'no-xl8, code, .codeTitle, .typeText, .copyable';

    const languageOptions = [ /* your full list unchanged */ ];

    let userSelectedLang = getLabVariable("TranslateLanguage");

    // Translation functions (translateText, translateElement, translateTextNodes unchanged)

    async function translateAllElements(parentSelector) {
        const parentElement = document.querySelector(parentSelector);
        if (!parentElement) {
            if (debug) console.log(`Parent '${parentSelector}' not found`);
            return;
        }
        const elements = parentElement.querySelectorAll(findElements);
        if (debug) console.log(`Translating ${elements.length} elements in ${parentSelector}`);
        await Promise.all(Array.from(elements).map(translateTextNodes));
        if (debug) console.log(`Completed translation for ${elements.length} elements in '${parentSelector}'`);
    }

    function revertTranslations() {
        translatedElements.forEach(element => {
            const originalText = element.getAttribute('data-original-text');
            if (originalText) element.textContent = originalText;
        });
        translatedElements.clear();
        if (debug) console.log("Reverted all translations");
    }

    function getTargetLanguage() {
        if (userSelectedLang && userSelectedLang !== 'auto') return userSelectedLang;

        let lang = document.documentElement.lang || "en-US";
        const langPrefix = lang.substr(0, 2).toLowerCase();
        if (langPrefix === "ja" || langPrefix === "ko") return langPrefix;
        return langPrefix;
    }

    function shouldTranslate(tl = targetLanguage) {
        const lower = (tl || "").toLowerCase();
        return lower !== 'en' && lower !== 'en-us' && lower !== 'en-gb';
    }

    let targetLanguage = getTargetLanguage();

    function getParentSelector() {
        const manual = userSelectedLang && userSelectedLang !== 'auto';
        return manual ? '#labClient' : (
            window.location.pathname.indexOf("ExamResult") < 0 ? '.instructions' : '.end-of-lab-report'
        );
    }

    // addLanguageDropdown function unchanged (with your modal selector '#settings-menu .modal-menu-content' if you have it)

    function initializeTranslation() {
        targetLanguage = getTargetLanguage();

        if (debug) {
            console.log("[Init] userSelectedLang =", userSelectedLang);
            console.log("[Init] targetLanguage =", targetLanguage);
            console.log("[Init] shouldTranslate =", shouldTranslate());
            console.log("[Init] parentSelector =", getParentSelector());
        }

        if (!shouldTranslate()) {
            revertTranslations();
            if (debug) console.log("Target English — skipped translation");
            return;
        }

        const parentSelector = getParentSelector();

        const observer = new MutationObserver(mutations => {
            let count = 0;
            mutations.forEach(mutation => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(node => {
                        if (node.nodeType !== 1) return;
                        const root = document.querySelector(parentSelector);
                        if (!root || (!node.closest(parentSelector) && !root.contains(node))) return;

                        if (elementArray.includes(node.tagName?.toLowerCase() || '')) {
                            translateTextNodes(node);
                            count++;
                        }
                        node.querySelectorAll(findElements).forEach(el => {
                            translateTextNodes(el);
                            count++;
                        });
                    });
                } else if (mutation.type === 'characterData') {
                    // Handle direct text changes inside existing elements
                    const parent = mutation.target.parentElement;
                    if (parent && parent.closest(parentSelector)) {
                        translateTextNodes(parent);
                        count += 1; // conservative count
                    }
                }
            });
            if (debug && count > 0) {
                console.log(`[Mutation] Translated approx ${count} new/changed items in '${parentSelector}'`);
            }
        });

        setTimeout(() => {
            translateAllElements(parentSelector);

            const observeRoot = document.querySelector('#labClient') || document.body;
            observer.observe(observeRoot, {
                childList: true,
                subtree: true,
                characterData: true
            });

            if (debug) console.log(`Observer attached to ${observeRoot.id || 'body'}`);
        }, 1500); // slightly longer delay for safety
    }

    addLanguageDropdown();
    initializeTranslation();
}
