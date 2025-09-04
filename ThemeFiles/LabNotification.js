/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 2.05
 * Date: 9/4/2025
 * Description: Displays lab notification popups using sendLabNotification API and integrates them into the notifications menu, creating the menu if it doesn't exist, ensuring no duplicates within a session using sessionStorage.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications v2.05"); }

    // Ensure notifications button exists
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
    const $page0 = document.getElementById("page0");
    if (!$page0) {
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
    const $client = document.getElementById("labClient");
    const $preview = document.getElementById("previewWrapper");
    return $client?.innerHTML || $preview?.innerHTML || "";
}

function ensureNotificationsButton() {
    let iconHolder = document.querySelector(".icon-holder");
    if (!iconHolder) {
        iconHolder = document.createElement("div");
        iconHolder.className = "icon-holder";
        // Try to append to a common parent like a header or nav, fallback to body
        const parent = document.querySelector("header, nav, #page0") || document.body;
        parent.appendChild(iconHolder);
        if (debug) { console.log(`Created icon-holder and appended to ${parent.tagName}${parent.id ? `#${parent.id}` : ''}`); }
    }

    if (!document.getElementById("notificationsButton")) {
        const notificationsButton = document.createElement("a");
        notificationsButton.id = "notificationsButton";
        notificationsButton.setAttribute("tabindex", "0");
        notificationsButton.setAttribute("data-target", "notifications-menu");
        notificationsButton.className = "notifications-button modal-menu-button icon primary-color-icon active";
        notificationsButton.setAttribute("role", "button");
        notificationsButton.setAttribute("aria-label", "Notifications");
        notificationsButton.setAttribute("title", "Notifications");
        // Fallback style for visibility
        notificationsButton.style.cssText = "display: inline-block; width: 24px; height: 24px; background: #007bff; border-radius: 4px; cursor: pointer;";
        iconHolder.insertBefore(notificationsButton, iconHolder.firstChild);
        if (debug) { console.log("Created notifications button"); }

        // Add click event listener to toggle notifications menu
        notificationsButton.addEventListener("click", () => {
            const menu = document.getElementById("notifications-menu");
            if (menu) {
                menu.style.display = menu.style.display === "none" ? "initial" : "none";
                if (debug) { console.log(`Toggled notifications menu to ${menu.style.display}`); }
            }
        });
    }
}

function ensureNotificationsMenu() {
    let notificationsMenu = document.getElementById("notifications-menu");
    if (!notificationsMenu) {
        notificationsMenu = document.createElement("div");
        notificationsMenu.id = "notifications-menu";
        notificationsMenu.className = "modal-menu page-background-color";
        notificationsMenu.setAttribute("role", "dialog");
        notificationsMenu.setAttribute("aria-modal", "true");
        notificationsMenu.setAttribute("aria-labelledby", "notifications-menu-title");
        notificationsMenu.style.display = "initial"; // Match provided HTML
        notificationsMenu.style.left = "16px";
        notificationsMenu.style.right = "16px";
        notificationsMenu.style.width = "initial";
        // Fallback style for visibility
        notificationsMenu.style.cssText += "background: #fff; border: 1px solid #ccc; padding: 10px; z-index: 1000; position: absolute;";

        const titleBar = document.createElement("div");
        titleBar.className = "modal-menu-title-bar primary-color-background";
        titleBar.innerHTML = `
            <h2 id="notifications-menu-title" class="modal-menu-title">Notifications</h2>
            <span><a class="close-modal-menu-button" tabindex="0" role="button" aria-label="Close" title="Close"></a></span>
        `;

        const contentDiv = document.createElement("div");
        contentDiv.className = "modal-menu-content";

        notificationsMenu.appendChild(titleBar);
        notificationsMenu.appendChild(contentDiv);
        // Append to a common parent or body
        const parent = document.querySelector("#page0") || document.body;
        parent.appendChild(notificationsMenu);
        if (debug) { console.log(`Created notifications menu and appended to ${parent.tagName}${parent.id ? `#${parent.id}` : ''}`); }

        // Add click event listener to close button
        const closeButton = notificationsMenu.querySelector(".close-modal-menu-button");
        if (closeButton) {
            closeButton.addEventListener("click", () => {
                notificationsMenu.style.display = "none";
                if (debug) { console.log("Closed notifications menu"); }
            });
        }
    }
    return notificationsMenu;
}

function appendNotificationToMenu(menu, id, content, date) {
    const contentDiv = menu.querySelector(".modal-menu-content");
    if (contentDiv.querySelector(`[data-id="${id}"]`)) {
        if (debug) { console.log(`Notification ${id} already exists in menu, skipping`); }
        return;
    }

    const notificationDiv = document.createElement("div");
    notificationDiv.setAttribute("data-id", id);
    notificationDiv.className = "listedNotification";
    notificationDiv.innerHTML = `
        <div class="listedNotificationDate">${date.toLocaleString()}</div>
        <div class="listedNotificationBody">${content}</div>
    `;
    contentDiv.appendChild(notificationDiv);
    if (debug) { console.log(`Added notification ${id} to menu`); }
}

// Execute immediately (timeout removed, add back if needed)
try {
    labNotifications();
} catch (err) {
    console.error("Lab notifications failed:", err);
}
// End lab Notification code
