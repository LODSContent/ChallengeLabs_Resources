/*
 * Script Name: AutoTranslate.js
 * Authors: Mark Morgan
 * Version: 2026.03.07 (conditional parent based on dropdown usage)
 * Description: Translates elements in the HTML to the target language.
 *              Uses page-language selectors for 'auto' mode;
 *              uses #labClient when user manually selects a language.
 */

// Begin Translation code

// Helper Functions (unchanged)
function getLabVariable(name) {
    try {
        if (debug) { console.log(`Retrieving lab variable - ${name}`); }
        try {
            clientAPI = window.api.v1;
        } catch(e) {
            clientAPI = null;
        }
        if (clientAPI) {
            if (debug) { console.log(`API: Getting lab variable - ${name}`); }             
            let value = window.api.v1.getLabVariable(name)?.toLowerCase() || null;
            if (debug) { console.log(`API: Retrieved lab variable - ${name} = ${value}`); }
            return value;
        } else {
            if (debug) { console.log(`NoAPI: Getting lab variable - ${name}`); }            
            let checkName = name.toLowerCase();
            let value = $('[data-name]').filter(function() {
                return $(this).attr('data-name').toLowerCase() == checkName
            }).val()?.toLowerCase() || null;
            if (debug) { console.log(`NoAPI: Retrieved lab variable - ${name} = ${value}`); }
            return value;
        }
    } catch (e) {
        if (debug) { console.log(`Failed to retrieve lab variable - ${name}`); }
        return null;
    }
}

function setLabVariable(name, value) {
    try {
        if (debug) { console.log(`Setting lab variable ${name} to ${value}`); }
        try {
            clientAPI = window.api.v1;
        } catch(e) {
            clientAPI = null;
        }
        if (clientAPI) {
            window.api.v1.setLabVariable(name, value);
        } else {
            $('[data-name="' + name + '"]').val(value).trigger("change");
        }
    } catch (e) {
        if (debug) { console.log(`Failed to set lab variable ${name} to ${value}`); }
    }
}

// Initialize debug early
let debug = "false";
debug = ["true", "yes"].includes(
    (getLabVariable("Debug") ?? getLabVariable("debug") ?? "").trim().toLowerCase()
);

// Get AutoTranslate setting
const autoTranslate = getLabVariable("AutoTranslate");
if (debug) { console.log(`AutoTranslate setting: ${autoTranslate}`); }

if (autoTranslate === 'no') {
    if (debug) { console.log("Skipping Translation."); }
} else {
    if (debug) { console.log("Starting Translation."); }

    // Configuration (unchanged)
    const translatedElements = new Set();
    const findElements = 'blockquote, table, a, p, h1, h2, h3, h4, ol, ul, li, details, span, input[type="button"], #labNotificationsHeader';
    const elementArray = findElements.replace('[type="button"]', '').split(',').map(s => s.trim().toLowerCase());
    const ignoreElements = 'no-xl8, code, .codeTitle, .typeText, .copyable';

    // Language options (unchanged)
    const languageOptions = [
        { code: 'af', name: 'Afrikaans' },
        { code: 'ar', name: 'Arabic' },
        { code: 'bg', name: 'Bulgarian' },
        { code: 'ca', name: 'Catalan' },
        { code: 'zh-CN', name: 'Chinese (Simplified)' },
        { code: 'zh-TW', name: 'Chinese (Traditional)' },
        { code: 'hr', name: 'Croatian' },
        { code: 'cs', name: 'Czech' },
        { code: 'da', name: 'Danish' },
        { code: 'nl', name: 'Dutch' },
        { code: 'en', name: 'English' },
        { code: 'et', name: 'Estonian' },
        { code: 'fi', name: 'Finnish' },
        { code: 'fr', name: 'French' },
        { code: 'de', name: 'German' },
        { code: 'el', name: 'Greek' },
        { code: 'he', name: 'Hebrew' },
        { code: 'hi', name: 'Hindi' },
        { code: 'hu', name: 'Hungarian' },
        { code: 'id', name: 'Indonesian' },
        { code: 'it', name: 'Italian' },
        { code: 'ja', name: 'Japanese' },
        { code: 'ko', name: 'Korean' },
        { code: 'lv', name: 'Latvian' },
        { code: 'lt', name: 'Lithuanian' },
        { code: 'no', name: 'Norwegian' },
        { code: 'pl', name: 'Polish' },
        { code: 'pt', name: 'Portuguese' },
        { code: 'ro', name: 'Romanian' },
        { code: 'ru', name: 'Russian' },
        { code: 'sk', name: 'Slovak' },
        { code: 'sl', name: 'Slovenian' },
        { code: 'es', name: 'Spanish' },
        { code: 'sv', name: 'Swedish' },
        { code: 'th', name: 'Thai' },
        { code: 'tr', name: 'Turkish' },
        { code: 'uk', name: 'Ukrainian' },
        { code: 'vi', name: 'Vietnamese' }
    ];

    // Get user-selected language
    let userSelectedLang = getLabVariable("TranslateLanguage");

    // Translation Functions (unchanged)
    async function translateText(text, targetLang) {
        try {
            const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            return data[0].map(item => item[0]).join('');
        } catch (error) {
            console.error('Translation error:', error);
            return text;
        }
    }

    async function translateElement(element) {
        if (element.closest(ignoreElements) || translatedElements.has(element)) {
            return;
        }
        const originalText = element.textContent.trim();
        if (!originalText) return;
        try {
            element.classList.add('translating');
            const translatedText = await translateText(originalText, targetLanguage);
            element.textContent = translatedText;
            translatedElements.add(element);
            element.setAttribute('data-original-text', originalText);
        } catch (error) {
            console.error('Error translating element:', error);
        } finally {
            element.classList.remove('translating');
        }
    }

    async function translateTextNodes(element) {
        const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, {
            acceptNode: node => node.parentElement.closest(ignoreElements) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT
        });
        const textNodes = [];
        let node;
        while ((node = walker.nextNode())) {
            textNodes.push(node);
        }
        for (const textNode of textNodes) {
            const originalText = textNode.nodeValue;
            const trimmedText = originalText.trim();
            if (!trimmedText) continue;
            try {
                const translatedText = await translateText(trimmedText, targetLanguage);
                textNode.nodeValue = originalText.replace(trimmedText, translatedText);
            } catch (error) {
                console.error('Error translating text node:', error);
            }
        }
        if (element.tagName === 'INPUT' && element.type === 'button') {
            const originalText = element.value;
            const trimmedText = originalText.trim();
            if (trimmedText) {
                try {
                    const translatedText = await translateText(trimmedText, targetLanguage);
                    element.value = originalText.replace(trimmedText, translatedText);
                } catch (error) {
                    console.error('Error translating button text:', error);
                }
            }
        }
    }

    async function translateAllElements(parentSelector) {
        const parentElement = document.querySelector(parentSelector);
        if (!parentElement) {
            if (debug) { console.log(`Parent '${parentSelector}' not found`); }
            return;
        }
        const elements = parentElement.querySelectorAll(findElements);
        await Promise.all(Array.from(elements).map(translateTextNodes));
        if (debug) { console.log(`Completed translation for ${elements.length} elements in '${parentSelector}'`); }
    }

    function revertTranslations() {
        translatedElements.forEach(element => {
            const originalText = element.getAttribute('data-original-text');
            if (originalText) {
                element.textContent = originalText;
            }
        });
        translatedElements.clear();
        if (debug) { console.log("Reverted all translations"); }
    }

    // Language selection logic
    function getTargetLanguage() {
        if (userSelectedLang && userSelectedLang !== 'auto') {
            return userSelectedLang;
        }
        let lang = document.documentElement.lang || "en-US";
        const langPrefix = lang.substr(0, 2).toLowerCase();
        if (langPrefix === "ja" || langPrefix === "ko") {
            return langPrefix;
        }
        return langPrefix;
    }

    let targetLanguage = getTargetLanguage();
    if (debug) { console.log(`Effective target language: ${targetLanguage}`); }

    // NEW: Decide which parent strategy to use
    function getParentSelector() {
        const isManualSelection = userSelectedLang && userSelectedLang !== 'auto';
        if (isManualSelection) {
            return '#labClient';
        }
        // Auto mode → original behavior
        return window.location.pathname.indexOf("ExamResult") < 0
            ? '.instructions'
            : '.end-of-lab-report';
    }

    // Add the dropdown to the settings modal (unchanged except selector comment)
    function addLanguageDropdown() {
        if (debug) { console.log(`Adding language dropdown.`); }
        const modalContent = document.querySelector('#settings-menu .modal-menu-content');
        if (!modalContent) {
            if (debug) { console.log("Modal content '#settings-menu .modal-menu-content' not found"); }
            return;
        }

        if (document.getElementById('translate-language-select')) {
            if (debug) { console.log("Dropdown already exists — skipping"); }
            return;
        }

        const html = `
            <h3 class="settings-heading primary-color"><label for="translate-language">Translate To</label></h3>
            <div>
                <select id="translate-language-select" data-name="TranslateLanguage">
                    <option value="auto" ${!userSelectedLang || userSelectedLang === 'auto' ? 'selected' : ''}>Auto (use page language)</option>
                    <option value="en" ${userSelectedLang === 'en' ? 'selected' : ''}>English (no translation)</option>
                    ${languageOptions.map(opt =>
                        `<option value="${opt.code}" ${userSelectedLang === opt.code ? 'selected' : ''}>${opt.name}</option>`
                    ).join('')}
                </select>
            </div>
            <hr>
        `;

        const lastHr = modalContent.querySelector('hr:last-child');
        if (lastHr) {
            lastHr.insertAdjacentHTML('afterend', html);
            if (debug) { console.log("Dropdown inserted after last <hr>"); }
        } else {
            modalContent.insertAdjacentHTML('beforeend', html);
            if (debug) { console.log("No <hr> found — appended to end"); }
        }

        const select = document.getElementById('translate-language-select');
        if (select) {
            select.addEventListener('change', async (e) => {
                const newLang = e.target.value;
                setLabVariable("TranslateLanguage", newLang);
                userSelectedLang = newLang;
                targetLanguage = getTargetLanguage();

                if (debug) { 
                    console.log(`Language changed to: ${newLang} → effective: ${targetLanguage}`); 
                    console.log(`Using parent: ${getParentSelector()}`);
                }

                revertTranslations();

                const parentSelector = getParentSelector();

                if (targetLanguage !== 'en' && targetLanguage !== 'en-us' && targetLanguage !== 'en-gb') {
                    await translateAllElements(parentSelector);
                }
            });
            if (debug) { console.log("Change listener attached"); }
        } else {
            if (debug) { console.log("Failed to find select after insertion"); }
        }
    }

    function initializeTranslation() {
        if (targetLanguage === 'en' || targetLanguage === 'en-us' || targetLanguage === 'en-gb') {
            if (debug) { console.log("Target is English — skipping translation"); }
            return;
        }

        const parentSelector = getParentSelector();

        const observer = new MutationObserver(mutations => {
            let newElementsTranslated = 0;
            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.closest(parentSelector)) {
                        const tagName = node.tagName.toLowerCase();
                        if (elementArray.includes(tagName) && (node.type === 'button' || tagName !== 'input')) {
                            translateTextNodes(node);
                            newElementsTranslated++;
                        }
                        const languageElements = node.querySelectorAll(findElements);
                        Array.from(languageElements).forEach(element => {
                            translateTextNodes(element);
                            newElementsTranslated++;
                        });
                    }
                });
            });
            if (debug && newElementsTranslated > 0) {
                console.log(`Translated ${newElementsTranslated} new elements in '${parentSelector}'`);
            }
        });

        setTimeout(() => {
            translateAllElements(parentSelector);
            observer.observe(document.body, { childList: true, subtree: true });
            if (debug) { 
                console.log(`Observer initialized using parent: '${parentSelector}'`); 
            }
        }, 1000);
    }

    // Main execution
    addLanguageDropdown();
    initializeTranslation();
}

// End Translation code
