/*
 * Script Name: LabNotifications.js
 * Authors: Mark Morgan
 * Version: 1.10
 * Date: March 08, 2025
 * Description: Translates elements in the HTML to the target language.
 */

// Begin lab Notification code
function labNotifications() {
    if (debug) { console.log("Starting lab notifications"); }

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

        // Build notification HTML
        const innerHTML = `<details><summary>${summary}</summary><br>${details}</details>`;
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
            if (debug) { console.log(`Displaying api notification: ${id}`); }
            //addHeader($page0);
            //addNotification($page0, id, type, innerHTML);
            window.api.v1.sendLabNotification(`${summary} \n\n${details}`);
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

function addHeader($node) {
    if (!document.getElementById("labNotificationsHeader")) {
        const header = document.createElement("h2");
        header.innerHTML = "Lab Notifications";
        header.className = "blink4 flash";
        header.id = "labNotificationsHeader";
        $node.appendChild(header);
        if (debug) { console.log("Added Lab Notifications header"); }
    }
}

function addNotification($node, id, type, innerHTML) {
    const labNotification = document.createElement("blockquote");
    labNotification.className = type;
    labNotification.title = "Lab Notification";
    labNotification.id = id;
    labNotification.innerHTML = innerHTML;
    $node.appendChild(labNotification);
    if (debug) { console.log(`Added notification element: ${id}`); }
}

// Execute immediately (timeout removed, add back if needed)
try {
    labNotifications();
} catch (err) {
    console.error("Lab notifications failed:", err);
}
// End lab Notification code
