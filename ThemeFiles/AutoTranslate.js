/*
 * Script Name: AutoTranslate.js
 * Authors: Mark Morgan
 * Version: 1.13
 * Date: March 09, 2025
 * Description: Translates elements in the HTML to the target language.
 */

// Begin Translation code

// Get AutoTranslate setting
//const autoTranslate = $('select[data-name="AutoTranslate"]').val()?.toLowerCase() || null;
const autoTranslate = $('.variable[data-name="AutoTranslate"]').text()?.toLowerCase() || null;
if (autoTranslate !== "yes" && autoTranslate !== "no" && autoTranslate !== null) {
    languageOverride = true;
} else {
    languageOverride = false;
    
}
if (debug) { console.log("languageOverride is:", languageOverride); }

if (debug) { console.log(`AutoTranslate setting: ${autoTranslate}`); }

if (autoTranslate === 'no') {
    if (debug) { console.log("Skipping Translation."); }
} else {
    if (debug) { console.log("Starting Translation."); }

    // Configuration
    const translatedElements = new Set();
    const findElements = 'blockquote, table, a, p, h1, h2, h3, h4, ol, ul, li, details, span, input[type="button"], #labNotificationsHeader';
    const elementArray = findElements.replace('[type="button"]', '').split(',').map(s => s.trim().toLowerCase());
    const ignoreElements = 'no-xl8, code, .codeTitle, .typeText, .copyable';
    const targetLanguage = getTargetLanguage();

    // Translation Functions
    async function translateText(text, targetLang) {
        try {
            const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            return data[0].map(item => item[0]).join('');
        } catch (error) {
            console.error('Translation error:', error);
            return text; // Fallback to original text
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

    async function translateAllElements(parent) {
        const parentElement = document.querySelector(parent);
        if (!parentElement) {
            if (debug) { console.log(`Parent element '${parent}' not found`); }
            return;
        }

        const elements = parentElement.querySelectorAll(findElements);
        await Promise.all(Array.from(elements).map(translateTextNodes));
        if (debug) { console.log(`Completed initial translation for ${elements.length} elements in '${parent}'`); }
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

    function initializeTranslation(parent) {
        if (targetLanguage === "en-US") {
            if (debug) { console.log("Target language is en-US, skipping translation"); }
            return;
        }

        const observer = new MutationObserver(mutations => {
            let newElementsTranslated = 0;

            mutations.forEach(mutation => {
                mutation.addedNodes.forEach(node => {
                    if (node.nodeType === 1 && node.closest(parent)) {
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
                console.log(`Translated ${newElementsTranslated} new elements in '${parent}'`);
            }
        });

        // Delay to catch late updates
        setTimeout(() => {
            translateAllElements(parent);
            observer.observe(document.body, { childList: true, subtree: true });
            if (debug) { console.log(`Translation observer initialized for '${parent}'`); }
        }, 1000);
    }

    // Helper Function
    function getTargetLanguage() {
        if (languageOverride) {
            lang = autoTranslate;
            document.documentElement.lang = autoTranslate;
        } else {
            lang = document.documentElement.lang || "en-US";
        }
        const langPrefix = lang.substr(0, 2).toLowerCase();
        if (langPrefix === "ja" || langPrefix === "ko") {
            lang = langPrefix;
        }
        return lang;
    }

    // Start Translation
    let parentSelector;
    if (window.location.pathname.indexOf("ExamResult") < 0) {
        if (languageOverride) {
            parentSelector = '.instructions-client';
        } else {
            parentSelector = '.instructions';
        }
    } else {
        parentSelector = '.end-of-lab-report';
    }
    initializeTranslation(parentSelector);
}

// End Translation code
