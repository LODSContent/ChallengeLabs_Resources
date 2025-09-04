/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.08
 * Date: 9/4/2025
 * Description: Displays lab notification popups using sendLabNotification API and merges them into the existing notifications menu's modal-menu-content, removing 'no notifications' message if present, ensuring no duplicates within a session using sessionStorage.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.08"); }

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

    const $contentDiv = $('#notifications-menu .modal-menu-content');
    if ($contentDiv.length === 0) {
        if (debug) { console.log("Notifications menu content div not found, aborting"); }
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
            // Add to notifications menu and remove 'no notifications' if present
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
    return $('#labClient').html() || $('#previewWrapper').html() || "";
}

function appendNotificationToMenu($contentDiv, id, content, date) {
    // Remove 'no notifications' message if present
    $contentDiv.find('.noNotifications').remove();

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
