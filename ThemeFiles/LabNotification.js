/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.14
 * Date: 9/4/2025
 * Description: Displays custom lab notification popups using sendLabNotification API and integrates them into a styled custom alerts menu with an icon using the lab-client-layout-v2 font (content: "\a016"), ensuring no duplicates within a session using sessionStorage.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.14"); }

    // Ensure custom alerts button exists
    ensureCustomAlertsButton();

    // Ensure custom alerts menu exists
    const customAlertsMenu = ensureCustomAlertsMenu();

    // Fetch notification data
    const uri = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/LabNotifications/labNotifications-dev.json';
    const messageObj = fetchNotifications(uri);
    if (!messageObj?.messages) {
        console.error("Failed to load or parse notifications");
        return;
    }
    if (debug) { console.log(`Loaded ${messageObj.messages.length} notification messages`); }

    const now = new Date();
    if ($('#page0').length === 0) {
        if (debug) { console.log("Page0 element not found, aborting"); }
        return;
    }

    const $contentDiv = $(customAlertsMenu).find('.modal-menu-content');
    if ($contentDiv.length === 0) {
        if (debug) { console.log("Custom alerts menu content div not found, aborting"); }
        return;
    }
    if (debug) { console.log("Found custom alerts menu content div"); }

    // Process each message
    messageObj.messages.forEach(message => {
        const { id, summary, details, queryString, startDate, endDate, type } = message;
        if (debug) { console.log(`Processing notification: ${id}, queryString: ${queryString}, bodyText: ${getBodyText()}`); }

        // Check if notification was already shown in this session
        const storageKey = `notification_${id}`;
        if (sessionStorage.getItem(storageKey)) {
            if (debug) { console.log(`Skipped notification: ${id} - already shown in this session`); }
            return;
        }

        // Build notification HTML
        const innerHTML = `${summary}<hr><br><br>${details}`;
        const regex = new RegExp(queryString, "is");

        // Date range check
        const start = startDate ? new Date(startDate) : new Date('1/1/1999');
        const end = endDate ? new Date(endDate) : new Date('1/1/2999');
        const isActive = start < now && end > now;

        // Get body content
        const bodyText = getBodyText();

        // Check conditions for display
        const exists = document.getElementById(id);
        if (bodyText.search(regex) !== -1 && !exists && isActive) {
            if (debug) { console.log(`Displaying notification: ${id}`); }
            // Send notification to system
            window.api.v1.sendLabNotification(innerHTML);
            // Add to custom alerts menu
            appendNotificationToMenu($contentDiv, id, innerHTML, now);
            // Mark notification as shown in sessionStorage
            sessionStorage.setItem(storageKey, 'shown');
        } else {
            if (debug) {
                console.log(`Skipped notification: ${id} - ${exists ? 'already exists' : !isActive ? 'outside date range' : 'no content match'}`);
            }
        }
    });
}

// Helper Functions
function fetchNotifications(url) {
    const xhttp = new XMLHttpRequest();
    xhttp.open("GET", url, false); // Synchronous
    xhttp.send();
    if (xhttp.status !== 200) {
        console.error(`Failed to fetch notifications: HTTP ${xhttp.status}`);
        return null;
    }
    return JSON.parse(xhttp.responseText);
}

function getBodyText() {
    // Use text content instead of HTML to improve matching
    return $('#labClient').text() || $('#previewWrapper').text() || "";
}

function ensureCustomAlertsButton() {
    let $iconHolder = $('.icon-holder');
    if ($iconHolder.length === 0) {
        $iconHolder = $('<div class="icon-holder"></div>');
        $('body').append($iconHolder);
        if (debug) { console.log("Created icon-holder"); }
    }

    if ($('#customAlertsButton').length === 0) {
        const $helpButton = $('.help-button');
        const $customAlertsButton = $('<a tabindex="0" id="customAlertsButton" data-target="custom-alerts-menu" class="custom-alerts-button modal-menu-button icon primary-color-icon" role="button" aria-label="Custom Alerts" title="Custom Alerts"></a>');
        $customAlertsButton.css({
            'display': 'inline-block',
            'width': '24px',
            'height': '24px',
            'cursor': 'pointer'
        });
        $customAlertsButton[0].setAttribute('data-icon', '\a016'); // Use lab-client-layout-v2 font character
        if ($helpButton.length > 0) {
            $customAlertsButton.insertBefore($helpButton);
        } else {
            $iconHolder.append($customAlertsButton);
        }
        if (debug) { console.log("Created custom alerts button"); }

        // Add click event listener to toggle custom alerts menu
        $customAlertsButton.on("click", () => {
            const $menu = $('#custom-alerts-menu');
            if ($menu.length > 0) {
                const currentDisplay = $menu.css('display');
                $menu.css('display', currentDisplay === 'none' ? 'initial' : 'none');
                if (debug) { console.log(`Toggled custom alerts menu to ${$menu.css('display')}`); }
            }
        });
    }
}

function ensureCustomAlertsMenu() {
    let $customAlertsMenu = $('#custom-alerts-menu');
    if ($customAlertsMenu.length === 0) {
        $customAlertsMenu = $('<div id="custom-alerts-menu" class="modal-menu page-background-color" role="dialog" aria-modal="true" aria-labelledby="custom-alerts-menu-title" style="display: none; left: 16px; right: 16px; width: initial;"></div>');
        const $titleBar = $('<div class="modal-menu-title-bar primary-color-background"></div>');
        $titleBar.append('<h2 id="custom-alerts-menu-title" class="modal-menu-title">Custom Alerts</h2>');
        $titleBar.append('<span><a class="close-modal-menu-button" tabindex="0" role="button" aria-label="Close" title="Close"></a></span>');
        $customAlertsMenu.append($titleBar);
        $customAlertsMenu.append('<div class="modal-menu-content"></div>');
        $customAlertsMenu.css({
            'border': '2px solid',
            'border-top-color': 'transparent',
            'border-bottom-color': '#007bff',
            'border-left-color': '#007bff',
            'border-right-color': '#007bff'
        });
        $('body').append($customAlertsMenu);
        if (debug) { console.log("Created custom alerts menu"); }

        // Add click event listener to close button
        $customAlertsMenu.find('.close-modal-menu-button').on("click", () => {
            $customAlertsMenu.css('display', 'none');
            if (debug) { console.log("Closed custom alerts menu"); }
        });
    }
    return $customAlertsMenu[0];
}

function appendNotificationToMenu($contentDiv, id, content, date) {
    if ($contentDiv.find(`[data-id="${id}"]`).length > 0) {
        if (debug) { console.log(`Notification ${id} already exists in menu, skipping`); }
        return;
    }

    const $notificationDiv = $('<div class="listedNotification"></div>');
    $notificationDiv.attr('data-id', id);
    $notificationDiv.append(`<div class="listedNotificationDate">${date.toLocaleString('en-US', { timeZoneName: 'short' })}</div>`);
    $notificationDiv.append(`<div class="listedNotificationBody">${content}</div>`);
    $contentDiv.append($notificationDiv);
    if (debug) { console.log(`Added notification ${id} to menu`); }
}

// Execute on document ready
$(document).ready(function() {
    try {
        labNotifications();
    } catch (err) {
        console.error("Lab notifications failed:", err);
    }
});
// End lab Notification code
