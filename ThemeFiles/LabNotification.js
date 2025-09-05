/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.18
 * Date: 9/5/2025
 * Description: Displays custom lab notification popups using sendLabNotification API and integrates them into a styled custom alerts menu with CSS ::before for the icon, managing modal-menu-mask for background darkening, persisting alerts within the same session using sessionStorage with full content, ensuring no duplicates and handling legacy data.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.18"); }

    // Ensure custom alerts button exists
    ensureCustomAlertsButton();

    // Ensure custom alerts menu exists
    const customAlertsMenu = ensureCustomAlertsMenu();

    // Restore previously saved alerts
    restoreSavedAlerts(customAlertsMenu);

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
        if (debug) { console.log(`Processing notification: ${id}, queryString: ${queryString}`); }

        // Check if notification was already shown
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
            // Save full alert content to sessionStorage
            const alertData = { summary, details, date: now.toLocaleString('en-US', { timeZoneName: 'short' }) };
            sessionStorage.setItem(storageKey, JSON.stringify(alertData));
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
        if ($helpButton.length > 0) {
            $customAlertsButton.insertBefore($helpButton);
        } else {
            $iconHolder.append($customAlertsButton);
        }
        if (debug) { console.log("Created custom alerts button"); }

        // Add click event listener to toggle custom alerts menu and mask
        $customAlertsButton.on("click", () => {
            const $menu = $('#custom-alerts-menu');
            const $mask = $('.modal-menu-mask');
            if ($menu.length > 0 && $mask.length > 0) {
                const currentDisplay = $menu.css('display');
                $menu.css('display', currentDisplay === 'none' ? 'initial' : 'none');
                $mask.css('display', currentDisplay === 'none' ? 'block' : 'none'); // Toggle mask with menu
                if (debug) { console.log(`Toggled custom alerts menu and mask to ${$menu.css('display')}`); }
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
        $('body').append($customAlertsMenu);
        if (debug) { console.log("Created custom alerts menu"); }

        // Ensure modal-menu-mask exists and is styled
        let $mask = $('.modal-menu-mask');
        if ($mask.length === 0) {
            $mask = $('<div class="modal-menu-mask" style="display: none;"></div>');
            $('body').append($mask);
            if (debug) { console.log("Created modal-menu-mask"); }
        }

        // Add click event listener to close button
        $customAlertsMenu.find('.close-modal-menu-button').on("click", () => {
            $customAlertsMenu.css('display', 'none');
            $('.modal-menu-mask').css('display', 'none');
            if (debug) { console.log("Closed custom alerts menu and mask"); }
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
    $notificationDiv.append(`<div class="listedNotificationDate">${date}</div>`);
    $notificationDiv.append(`<div class="listedNotificationBody">${content}</div>`);
    $contentDiv.append($notificationDiv);
    if (debug) { console.log(`Added notification ${id} to menu`); }
}

function restoreSavedAlerts(customAlertsMenu) {
    const $contentDiv = $(customAlertsMenu).find('.modal-menu-content');
    const savedAlerts = Object.keys(sessionStorage).filter(key => key.startsWith('notification_'));
    if (debug) { console.log(`Restoring ${savedAlerts.length} saved alerts`); }
    savedAlerts.forEach(key => {
        const id = key.replace('notification_', '');
        const savedData = sessionStorage.getItem(key);
        if (savedData) {
            try {
                const data = JSON.parse(savedData);
                if (data && !$contentDiv.find(`[data-id="${id}"]`).length) {
                    const $notificationDiv = $('<div class="listedNotification"></div>');
                    $notificationDiv.attr('data-id', id);
                    $notificationDiv.append(`<div class="listedNotificationDate">${data.date}</div>`);
                    $notificationDiv.append(`<div class="listedNotificationBody">${data.summary}<hr><br><br>${data.details}</div>`);
                    $contentDiv.append($notificationDiv);
                    if (debug) { console.log(`Restored notification ${id} from sessionStorage`); }
                }
            } catch (e) {
                if (debug) { console.log(`Skipping invalid JSON for ${id}: ${e.message}, data: ${savedData}`); }
                // Handle legacy "shown" string by removing it
                if (savedData === 'shown') {
                    sessionStorage.removeItem(key);
                    if (debug) { console.log(`Removed legacy 'shown' entry for ${id}`); }
                }
            }
        }
    });
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
