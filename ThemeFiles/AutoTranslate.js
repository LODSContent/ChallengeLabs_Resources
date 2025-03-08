// Begin Translation code

// Get the AutoTranslate variable setting
try {autoTranslate = $('select[data-name="AutoTranslate"]').val().toLowerCase();} catch (err) {autoTranslate = null}

// Retrieve the appropriate language file from github
if (autoTranslate == 'no') {  
  console.log("Skipping Translation.");
} else {
  // Store translated elements to prevent duplicate translations
  console.log("Starting Translation.");
  const translatedElements = new Set();
  const findElements = 'blockquote, table, a, p, h1, h2, h3, h4, ol, ul, li, details, span, input[type="button"], #labNotificationsHeader';
  const elementArray = findElements.replace('[type="button"]','').split(",")
  const ignoreElements = 'no-xl8, code, .codeTitle, .typeText, .copyable';
  
  // Get target language from HTML lang attribute, fallback to 'en'    
  try {targetLanguage = document.documentElement.lang} catch(err) {labLanguageCode = "en-US"}
    
  if(targetLanguage != "en-US") {
    if (targetLanguage.substr(0,2).toLowerCase() == "ja" || targetLanguage.substr(0,2).toLowerCase() == "ko") {
      targetLanguage = targetLanguage.substr(0,2)
    }     
    
    async function translateText(text, targetLang) {
        try {
            const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
            const response = await fetch(url);
            const data = await response.json();
            return data[0].map(item => item[0]).join('');
        } catch (error) {
            console.error('Translation error:', error);
            return text; // Return original text if translation fails
        }
    }
    
    async function translateElement(element) {
        // Skip elements within <no-xl8> or other listed tags
        const closestElement = element.closest(ignoreElements);
        if (closestElement) {
            return;
        }
    
        // Skip if already translated
        if (translatedElements.has(element)) {
            return;
        }
    
        const originalText = element.textContent.trim();
        if (!originalText) return;
    
        try {
            // Add loading indicator
            element.classList.add('translating');
            
            const translatedText = await translateText(originalText, targetLanguage);
            
            // Update the element content
            element.textContent = translatedText;
            
            // Mark as translated
            translatedElements.add(element);
            
            // Store original text as data attribute
            element.setAttribute('data-original-text', originalText);
        } catch (error) {
            console.error('Error translating element:', error);
        } finally {
            element.classList.remove('translating');
        }
    }
    
    async function translateTextNodes(element) {
        const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, null, false);
        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            // Skip text nodes within ignored elements
            if (node.parentElement.closest(ignoreElements)) {
                continue;
            }      
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
    
        // Handle button text separately
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
        if (!parentElement) return;
    
        const elements = parentElement.querySelectorAll(findElements);
        const translations = Array.from(elements).map(element => 
            translateTextNodes(element)
        );
        await Promise.all(translations);
    }
    
    function revertTranslations() {
        translatedElements.forEach(element => {
            const originalText = element.getAttribute('data-original-text');
            if (originalText) {
                element.textContent = originalText;
            }
        });
        translatedElements.clear();
    }
    
    function initializeTranslation (parent) {
      try {
        // Initialize translation observer
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === 1) { // ELEMENT_NODE
                        //if (['BLOCKQUOTE', 'TABLE', 'A', 'P', 'H1', 'H2', 'H3', 'H4', 'OL', 'UL', 'DETAILS', 'SPAN', 'INPUT'].includes(node.tagName) && (node.type === 'button' || node.tagName !== 'INPUT')) {
                        if (node.closest(parent) && elementArray.includes(node.tagName.toLowerCase) && (node.type === 'button' || node.tagName !== 'INPUT')) {
                            translateTextNodes(node);
                        }
                        // Check for specified elements inside the added node
                        const languageElements = node.querySelectorAll(findElements);
                        Array.from(languageElements).forEach(element => 
                            translateTextNodes(element)
                        );
                    }
                });
            });
        });
    
        // Perform initial translation
        translateAllElements(parent);
        
        // Start observing the document
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    
        // Add methods to window object for manual control
        window.translatePage = translateAllElements;
        window.revertTranslations = revertTranslations;
      } catch(err) {};
    }

    if (window.location.pathname.indexOf("ExamResult") < 0) {
      //setTimeout(()=>{
        initializeTranslation('.instructions');
      //}, 2000);
    } else {
      //setTimeout(()=>{
        initializeTranslation('.end-of-lab-report');
      //}, 2000);
    }
  }
}
// End Translation code

