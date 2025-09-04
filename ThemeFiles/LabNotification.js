/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.07
 * Date: 9/4/2025
 * Description: Displays lab notification popups using sendLabNotification API and integrates them into the existing notifications menu, fixing visibility of notificationsButton with CSS override, ensuring no duplicates within a session using sessionStorage.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.07"); }

    // Ensure notifications button is visible and exists
    ensureNotificationsButton();

    // Ensure notifications menu exists
    const notificationsMenu = ensureNotificationsMenu();

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
            // Add to notifications menu
            appendNotificationToMenu(notificationsMenu, id, innerHTML, now);
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

function ensureNotificationsButton() {
    let $iconHolder = $('.icon-holder');
    if ($iconHolder.length === 0) {
        $iconHolder = $('<div class="icon-holder"></div>');
        $('body').append($iconHolder);
        if (debug) { console.log("Created icon-holder"); }
    }

    if ($('#notificationsButton').length === 0) {
        const $notificationsButton = $('<a tabindex="0" id="notificationsButton" data-target="notifications-menu" class="notifications-button modal-menu-button icon primary-color-icon active" role="button" aria-label="Notifications" title="Notifications"></a>');
        $iconHolder.append($notificationsButton);
        if (debug) { console.log("Created notifications button"); }
    }

    // Override CSS visibility
    $('#notificationsButton').css('visibility', 'visible');
    if (debug) { console.log("Set notifications button visibility to visible"); }
}

function ensureNotificationsMenu() {
    let $notificationsMenu = $('#notifications-menu');
    if ($notificationsMenu.length === 0) {
        $notificationsMenu = $('<div id="notifications-menu" class="modal-menu page-background-color" role="dialog" aria-modal="true" aria-labelledby="notifications-menu-title" style="display: none; left: 16px; right: 16px; width: initial;"></div>');
        const $titleBar = $('<div class="modal-menu-title-bar primary-color-background"></div>');
        $titleBar.append('<h2 id="notifications-menu-title" class="modal-menu-title">Notifications</h2>');
        $titleBar.append('<span><a class="close-modal-menu-button" tabindex="0" role="button" aria-label="Close" title="Close"></a></span>');
        $notificationsMenu.append($titleBar);
        $notificationsMenu.append('<div class="modal-menu-content"></div>');
        $('body').append($notificationsMenu);
        if (debug) { console.log("Created notifications menu"); }
    }
    return $notificationsMenu[0];
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
