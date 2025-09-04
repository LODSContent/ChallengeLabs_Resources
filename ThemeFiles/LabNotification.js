/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.06
 * Date: 9/4/2025
 * Description: Displays custom lab notification popups using sendLabNotification API and integrates them into a new custom alerts menu, creating the menu and icon if they don't exist, ensuring no duplicates within a session using sessionStorage.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.06"); }

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

    // Process each message
    messageObj.messages.forEach(message => {
        const { id, summary, details, queryString, startDate, endDate, type } = message;
        if (debug) { console.log(`Processing notification: ${id}`); }

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
            appendNotificationToMenu(customAlertsMenu, id, innerHTML, now);
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
    return $('#labClient').html() || $('#previewWrapper').html() || "";
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
            'width': '32px',
            'height': '32px',
            'background-color': '#007bff',
            'background-image': 'url(data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSIjZmZmIj48cGF0aCBkPSJNMTkgMTJoLTR2LTZjMC0xLjEwNy0uODkzLTItMi0ycy0yIC44OTMtMiAydi02aC00YzEuNjY3IDEuMzMzIDQtMy42NjcgNC01IDAtMS43MzMgMS4yNjctMyAzLTMzIDEuNzMzIDAgMyAxLjI2NyAzIDN6bS00IDZjMCAxLjEwNy44OTMgMiAyIDJoMnY2aDR2Mmg0di0yaC00di02YzAtMS4xMDctLjg5My0yLTItMmgtdjJoLTR6IiAvPjwvc3ZnPg==)',
            'background-repeat': 'no-repeat',
            'background-position': 'center',
            'background-size': '16px',
            'border-radius': '4px',
            'cursor': 'pointer'
        });
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
                $menu.css('display', $menu.css('display') === 'none' ? 'initial' : 'none');
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

function appendNotificationToMenu(menu, id, content, date) {
    const $menu = $(menu);
    const $contentDiv = $menu.find(".modal-menu-content");
    if ($contentDiv.find(`[data-id="${id}"]`).length > 0) {
        if (debug) { console.log(`Notification ${id} already exists in menu, skipping`); }
        return;
    }
    const $notificationDiv = $('<div class="listedNotification"></div>');
    $notificationDiv.attr('data-id', id);
    $notificationDiv.append(`<div class="listedNotificationDate">${date.toLocaleString()}</div>`);
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
