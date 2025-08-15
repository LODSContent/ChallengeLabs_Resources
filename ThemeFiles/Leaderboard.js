/*
 * Script Name: Leaderboard.js
 * Authors: Mark Morgan
 * Version: 1.18
 * Date: August 15, 2025
 * Description: Posts scores to the MarcoScore leaderboard application, with case-insensitive game ID
 * handling (displayed in uppercase) and timeout management for server requests. The game ID
 * entry form is placed in a "Leaderboard" section under a "Challenge Labs" tab, with a
 * display for the server-generated player name and errors. The scoreboard name is displayed
 * next to the Leaderboard header, retrieved from the POST /submit response. The player name
 * is displayed in h3 format, preceded by the text "Your Player Name Is: " in normal text,
 * both on the same line, one line below the gameID input box and submit button. Tab-switching
 * logic ensures visibility with a green underline, respecting the page's default tab. Separate
 * MutationObservers watch for dynamically added "scriptTask pass" elements (attribute changes)
 * and "feedback positive" elements (child list and attribute changes) to trigger scoring after
 * successful validation, with duplicate prevention for both scriptTasks and feedbackItems.
 */
//if (typeof debug === 'undefined') { var debug = false; } // Ensure debug is defined
if (debug) { console.log("Leaderboard: Script is loading"); }
// begin shared functions
// Retrieve a lab variable listed in Markdown as a case-insensitive variable name
function getLabVariable(name) {
    if (debug) { console.log(`Leaderboard: Retrieving lab variable - ${name}`); }
    let checkName = name.toLowerCase();
    let value = $('[data-name]').filter(function() { return $(this).attr('data-name').toLowerCase() == checkName }).val();
    if (debug) { console.log(`Leaderboard: Retrieved value for ${name} - ${value}`); }
    return value;
}
// Set a lab variable
function setLabVariable(name, value) {
    if (debug) { console.log(`Leaderboard: Setting lab variable ${name} to ${value}`); }
    $('[data-name="' + name + '"]').val(value).trigger("change");
}
// Handle tab switching
function initializeTabSwitching() {
    if (debug) { console.log("Leaderboard: Checking for existing tab-switching logic"); }
    // Check if existing handler exists
    const hasExistingHandler = $('#tabHolder').data('events') && $('#tabHolder').data('events').click;
    if (!hasExistingHandler) {
        if (debug) { console.log("Leaderboard: Initializing tab switching"); }
        $('#tabHolder').on('click', '.tabHeading', function() {
            if (debug) { console.log(`Leaderboard: Tab clicked - ${$(this).data('target')}`); }
            // Remove selected state from all tabs
            $('.tabHeading').removeClass('selected').attr('aria-selected', 'false').attr('tabindex', '-1');
            // Add selected state to clicked tab
            $(this).addClass('selected').attr('aria-selected', 'true').attr('tabindex', '0');
            // Hide all tab content
            $('.tab').css('display', 'none');
            // Show target tab content
            const target = $(this).data('target');
            $(`#${target}`).css('display', 'block');
            if (debug) { console.log(`Leaderboard: Showing tab content - ${target}`); }
        });
    } else {
        if (debug) { console.log("Leaderboard: Existing tab-switching logic detected, skipping initialization"); }
    }
}
// end shared functions
// begin leaderboard lab code
let leaderboard = getLabVariable('Leaderboard');
if (leaderboard) {
    if (debug) { console.log("Leaderboard: Leaderboard enabled, proceeding with initialization"); }
  
    // Initialize the player on the leaderboard
    function initPlayer() {
        if (debug) { console.log("Leaderboard: Initializing player"); }
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            return;
        }
        lab.Variable.gameID = $('#gameID').val().toUpperCase(); // Normalize to uppercase
        if (debug) { console.log(`Leaderboard: Player data - GameID: ${lab.Variable.gameID}`); }
      
        // Update gameID input field to show uppercase
        $('#gameID').val(lab.Variable.gameID);
      
        if (lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Initializing player for marcoscore"); }
            let leaderboardURL = 'https://marcoscore.cyberjunk.com/submit'; // Hardcoded server address
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "gameID": lab.Variable.gameID,
                "playerName": lab.Variable.playerName || "", // Allow server to generate name
                "scoreAdd": lab.Variable.totalScore
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.timeout = 5000; // Set 5-second timeout
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: marcoscore player initialization successful"); }
                    let response = JSON.parse(xhttp.responseText);
                    if (response.success && response.playerName) {
                        if (debug) { console.log("Leaderboard: Received playerName from marcoscore response"); }
                        lab.Variable.playerName = response.playerName;
                        $('#player-name-display').text(response.playerName); // Update only the h3 with player name
                        if (response.scoreboardName) {
                            if (debug) { console.log(`Leaderboard: Received scoreboardName - ${response.scoreboardName}`); }
                            $('#leaderboard-header').text(`Leaderboard: ${response.scoreboardName}`);
                        }
                        if (debug) { console.log(`Leaderboard: Updated playerName to ${lab.Variable.playerName}`); }
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    }
                } else if (this.readyState === 4) {
                    if (debug) { console.log(`Leaderboard: marcoscore player initialization failed - Status: ${this.status}`); }
                    let errorMessage = this.status === 204 ? 'Invalid Game ID. Please check and try again.' : `Failed to initialize player (Status: ${this.status}). Please try again.`;
                    $('#leaderboard-error').html(`<div style="color: red;">${errorMessage}</div>`);
                }
            };
            xhttp.ontimeout = function() {
                if (debug) { console.log("Leaderboard: marcoscore player initialization timed out"); }
                $('#leaderboard-error').html('<div style="color: red;">Error: Request to MarcoScore timed out. Please check Game ID and try again.</div>');
            };
        } else {
            if (debug) { console.log("Leaderboard: Invalid gameID, skipping initialization"); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Game ID is required.</div>');
        }
        if (debug) { console.log("Leaderboard: Saving updated lab variables"); }
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
  
    // Post a score to the leaderboard server
    function postScore(score) {
        if (debug) { console.log(`Leaderboard: Posting score - ${score}`); }
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            return;
        }
        lab.Variable.gameID = lab.Variable.gameID.toUpperCase(); // Normalize to uppercase
        if (lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Posting score to marcoscore"); }
            let leaderboardURL = 'https://marcoscore.cyberjunk.com/submit'; // Hardcoded server address
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "gameID": lab.Variable.gameID,
                "playerName": lab.Variable.playerName || "", // Allow server to generate name
                "scoreAdd": score
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.timeout = 5000; // Set 5-second timeout
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: marcoscore score post successful"); }
                    let response = JSON.parse(xhttp.responseText);
                    if (response.success && response.playerName) {
                        if (debug) { console.log("Leaderboard: Received playerName from marcoscore response"); }
                        lab.Variable.playerName = response.playerName;
                        $('#player-name-display').text(response.playerName); // Update only the h3 with player name
                        if (response.scoreboardName) {
                            if (debug) { console.log(`Leaderboard: Received scoreboardName - ${response.scoreboardName}`); }
                            $('#leaderboard-header').text(`Leaderboard: ${response.scoreboardName}`);
                        }
                        if (debug) { console.log(`Leaderboard: Updated playerName to ${lab.Variable.playerName}`); }
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    }
                } else if (this.readyState === 4) {
                    if (debug) { console.log(`Leaderboard: marcoscore score post failed - Status: ${this.status}`); }
                    let errorMessage = this.status === 204 ? 'Invalid Game ID. Please check and try again.' : `Failed to post score (Status: ${this.status}). Please try again.`;
                    $('#leaderboard-error').html(`<div style="color: red;">${errorMessage}</div>`);
                }
            };
            xhttp.ontimeout = function() {
                if (debug) { console.log("Leaderboard: marcoscore score post timed out"); }
                $('#leaderboard-error').html('<div style="color: red;">Error: Score post to MarcoScore timed out. Please check Game ID and try again.</div>');
            };
        } else {
            if (debug) { console.log("Leaderboard: Invalid gameID, skipping score post"); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Game ID is required.</div>');
        }
        if (debug) { console.log("Leaderboard: Saving updated lab variables after score post"); }
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
  
    // Handle step clicks for penalties
    function stepClicked(step) {
        if (debug) { console.log(`Leaderboard: Processing step click - Step ${step}`); }
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            return;
        }
        for (let i = 0; i < lab.stepItems.length; i++) {
            if (lab.stepItems[i].stepNumber == step) {
                try {
                    let clicked = lab.stepItems[i].clicked;
                    if (clicked == "False") {
                        if (debug) { console.log(`Leaderboard: Step ${step} not previously clicked, applying penalty`); }
                        lab.Variable.totalPenalty = parseInt(lab.Variable.totalPenalty) + parseInt(lab.Variable.stepPenalty);
                        let score = parseInt(lab.Variable.stepPenalty) * -1;
                        if (debug) { console.log(`Leaderboard: Calculated penalty score - ${score}`); }
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                        postScore(score);
                        lab = JSON.parse($('[data-name="labVariables"]').val());
                        lab.stepItems[i].clicked = "True";
                        if (debug) { console.log(`Leaderboard: Marked step ${step} as clicked`); }
                    }
                } catch (e) {
                    if (debug) { console.log(`Leaderboard: Error processing step ${step} - ${e.message}`); }
                }
            }
        }
        if (debug) { console.log("Leaderboard: Saving updated lab variables after step click"); }
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
  
    // Handle script task scoring
    function getScriptTasks() {
        if (debug) { console.log("Leaderboard: Checking for completed script tasks"); }
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            return;
        }
        var scoredTasks = lab.scriptTasks || [];
        if (debug) { console.log(`Leaderboard: Current scoredTasks: ${JSON.stringify(scoredTasks)}`); }
        var scriptTasks = $('.scriptTask.pass').map(function() {
            const id = $(this).data("id");
            if (debug) { console.log(`Leaderboard: Found scriptTask.pass with ID ${id}`); }
            return id;
        }).get();
        for (let i = 0; i < scriptTasks.length; i++) {
            try {
                const taskId = parseInt(scriptTasks[i]);
                if (!scoredTasks.includes(taskId) && scriptTasks[i] != "" && scriptTasks[i] != null) {
                    if (debug) { console.log(`Leaderboard: Found new scored task - ID ${taskId}`); }
                    scoredTasks.push(taskId);
                    let score = parseInt(lab.Variable.scoreValue) || 1000;
                    if (debug) { console.log(`Leaderboard: Calculated task score - ${score}`); }
                    postScore(score);
                    lab = JSON.parse($('[data-name="labVariables"]').val());
                    lab.scriptTasks = scoredTasks;
                    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                } else if (scoredTasks.includes(taskId)) {
                    if (debug) { console.log(`Leaderboard: Skipping already scored task - ID ${taskId}`); }
                }
            } catch (e) {
                if (debug) { console.log(`Leaderboard: Error processing task ${scriptTasks[i]} - ${e.message}`); }
            }
        }
        if (debug) { console.log(`Leaderboard: Saving updated lab variables with scored tasks: ${JSON.stringify(scoredTasks)}`); }
        lab.scriptTasks = scoredTasks;
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
  
    // Handle feedback scoring
    function getFeedbackScores() {
        if (debug) { console.log("Leaderboard: Checking for positive feedback elements"); }
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            return;
        }
        var scoredFeedbacks = lab.feedbackItems || [];
        if (debug) { console.log(`Leaderboard: Current scoredFeedbacks: ${JSON.stringify(scoredFeedbacks)}`); }
        var feedbackItems = $('.feedbackHolder .feedback.positive').map(function() {
            const id = $(this).parent().attr('id');
            if (debug) { console.log(`Leaderboard: Found feedback.positive with parent ID ${id}`); }
            return id;
        }).get();
        for (let i = 0; i < feedbackItems.length; i++) {
            try {
                if (!scoredFeedbacks.includes(feedbackItems[i]) && feedbackItems[i] != "" && feedbackItems[i] != null) {
                    if (debug) { console.log(`Leaderboard: Found new positive feedback - ID ${feedbackItems[i]}`); }
                    scoredFeedbacks.push(feedbackItems[i]);
                    let score = parseInt(lab.Variable.scoreValue) || 1000;
                    if (debug) { console.log(`Leaderboard: Calculated feedback score - ${score}`); }
                    postScore(score);
                    lab = JSON.parse($('[data-name="labVariables"]').val());
                    lab.feedbackItems = scoredFeedbacks;
                    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                } else if (scoredFeedbacks.includes(feedbackItems[i])) {
                    if (debug) { console.log(`Leaderboard: Skipping already scored feedback - ID ${feedbackItems[i]}`); }
                }
            } catch (e) {
                if (debug) { console.log(`Leaderboard: Error processing feedback ${feedbackItems[i]} - ${e.message}`); }
            }
        }
        if (debug) { console.log(`Leaderboard: Saving updated lab variables with scored feedback: ${JSON.stringify(scoredFeedbacks)}`); }
        lab.feedbackItems = scoredFeedbacks;
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
  
    // Initialize leaderboard functionality
    function initializeLeaderboard() {
        if (debug) { console.log("Leaderboard: Starting initialization"); }
        if ($('[id="editorWrapper"]').length == 0 && getLabVariable('Leaderboard')) {
            if (debug) { console.log("Leaderboard: Editor wrapper not present and Leaderboard variable set, proceeding"); }
            // Initialize separate MutationObservers for script tasks and feedback
            const scriptTaskObserver = new MutationObserver((mutations) => {
                if (debug) { console.log("Leaderboard: Detected scriptTask mutation"); }
                mutations.forEach(mu => {
                    if (mu.type !== "attributes" || mu.attributeName !== "class" || !mu.target.classList.contains('pass')) return;
                    if (debug) { console.log("Leaderboard: Valid scriptTask.pass mutation detected"); }
                    getScriptTasks();
                });
            });
            const feedbackObserver = new MutationObserver((mutations) => {
                if (debug) { console.log("Leaderboard: Detected feedbackHolder mutation"); }
                mutations.forEach(mu => {
                    if (mu.type === "childList") {
                        if (debug) { console.log("Leaderboard: Checking for new feedback.positive elements"); }
                        mu.addedNodes.forEach(node => {
                            if (node.nodeType === 1 && node.classList.contains('feedback') && node.classList.contains('positive')) {
                                if (debug) { console.log("Leaderboard: Valid feedback.positive node added"); }
                                getFeedbackScores();
                            }
                        });
                    } else if (mu.type === "attributes" && mu.attributeName === "class" && mu.target.classList.contains('positive')) {
                        if (debug) { console.log("Leaderboard: Valid feedback.positive class change detected"); }
                        getFeedbackScores();
                    }
                });
            });
            // Observe scriptTask elements
            const scriptTasks = document.querySelectorAll(".scriptTask");
            if (debug) { console.log(`Leaderboard: Observing ${scriptTasks.length} scriptTask elements`); }
            scriptTasks.forEach(el => scriptTaskObserver.observe(el, { attributes: true }));
            // Observe feedbackHolder elements for child list and attribute changes
            const feedbackHolders = document.querySelectorAll(".feedbackHolder");
            if (debug) { console.log(`Leaderboard: Observing ${feedbackHolders.length} feedbackHolder elements`); }
            feedbackHolders.forEach(el => feedbackObserver.observe(el, { childList: true, subtree: true, attributes: true, attributeFilter: ['class'] }));
            // Watch document for new feedbackHolder elements
            const documentObserver = new MutationObserver((mutations) => {
                if (debug) { console.log("Leaderboard: Detected document mutation, checking for new feedbackHolder elements"); }
                mutations.forEach(mu => {
                    mu.addedNodes.forEach(node => {
                        if (node.nodeType === 1 && node.classList.contains('feedbackHolder')) {
                            if (debug) { console.log(`Leaderboard: New feedbackHolder detected - ID ${node.id}`); }
                            feedbackObserver.observe(node, { childList: true, subtree: true, attributes: true, attributeFilter: ['class'] });
                        }
                    });
                });
            });
            documentObserver.observe(document.body, { childList: true, subtree: true });
  
            // Get the lab variables
            try {
                var lab = JSON.parse($('[data-name="labVariables"]').val());
                if (debug) { console.log("Leaderboard: Successfully parsed lab variables"); }
            } catch (e) {
                if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
                $('#leaderboard-error').html('<div style="color: red;">Error: Lab variables not found.</div>');
            }
          
            // Find all stepItem class elements and put them in an array
            const foundSteps = $('[class^="stepItem"], .hint > details, .know-icon > summary, .hint-icon > summary, .moreKnowledge');
            const stepItems = [];
            for (let i = 0; i < foundSteps.length; i++) {
                foundSteps[i].setAttribute('itemNumber', i); // Fix indexing to use [i]
                const obj = {
                    stepNumber: i,
                    clicked: 'False'
                };
                stepItems.push(obj);
                foundSteps[i].addEventListener('click', () => stepClicked(i)); // Replace eval with direct listener
                if (debug) { console.log(`Leaderboard: Adding click listener for step ${i}`); }
            }
            if (debug) { console.log(`Leaderboard: Registered ${stepItems.length} step items`); }
          
            // If no saved lab variables, establish a new lab object with defaults
            if (!lab) {
                if (debug) { console.log("Leaderboard: No lab variables found, setting defaults"); }
                // Defaults for variables
                const debugVar = getLabVariable('debug') || "False";
                const serverType = 'marcoscore'; // Only support marcoscore
                const serverAddress = 'marcoscore.cyberjunk.com'; // Hardcoded
                let gameID = getLabVariable('GameID') || "";
                if (gameID) gameID = gameID.toUpperCase(); // Normalize default gameID
                const playerName = getLabVariable('PlayerName') || "";
                const stepPenalty = getLabVariable('StepPenalty') || 100;
                const totalPenalty = getLabVariable('TotalPenalty') || 0;
                const scoreValue = getLabVariable('ScoreValue') || 1000; // Default to 1000
                const totalScore = getLabVariable('TotalScore') || 0;
                const leaderboard = getLabVariable('Leaderboard') || "False";
                // Creating a labVariables object
                const labVariables = {
                    debug: debugVar,
                    serverType,
                    serverAddress,
                    gameID,
                    playerName,
                    stepPenalty,
                    totalPenalty,
                    scoreValue,
                    totalScore,
                    leaderboard
                };
                // Creating a lab object to store everything
                lab = {
                    Variable: labVariables,
                    stepItems,
                    feedbackItems: [] // Initialize feedbackItems for tracking scored feedback
                };
                if (debug) { console.log("Leaderboard: Default lab variables set"); }
            }
          
            // Save the lab object
            if (debug) { console.log("Leaderboard: Saving initial lab variables"); }
            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
  
            // Add or update Challenge Labs tab
            if (lab.Variable.leaderboard != 'False') {
                if (debug) { console.log("Leaderboard: Preparing to add Challenge Labs tab"); }
                const tabHolder = $('#tabHolder');
                if (tabHolder.length === 0) {
                    if (debug) { console.log("Leaderboard: Error: #tabHolder not found"); }
                    $('#leaderboard-error').html('<div style="color: red;">Error: Tab holder not found.</div>');
                    return;
                }
                const challengeLabsTab = $('[data-target="challengeLabsTab"]');
                const nextTabId = tabHolder.find('.tabHeading').length; // Next ID after existing tabs
                if (challengeLabsTab.length === 0) {
                    if (debug) { console.log("Leaderboard: Creating new Challenge Labs tab"); }
                    tabHolder.append(`
                        <a tabindex="-1" class="tabHeading tab-heading primary-color-border" aria-selected="false" role="tab" aria-label="Challenge Labs" data-target="challengeLabsTab" data-id="${nextTabId}">Challenge Labs</a>
                    `);
                }
                // Add or update Leaderboard section in Challenge Labs tab
                const tabsContainer = $('.tabs');
                if (tabsContainer.length === 0) {
                    if (debug) { console.log("Leaderboard: Error: .tabs container not found"); }
                    $('#leaderboard-error').html('<div style="color: red;">Error: Tabs container not found.</div>');
                    return;
                }
                let challengeLabsContent = $('#challengeLabsTab');
                if (challengeLabsContent.length === 0) {
                    if (debug) { console.log("Leaderboard: Creating Challenge Labs tab content"); }
                    tabsContainer.append(`
                        <div id="challengeLabsTab" class="tab tab-content zoomable" style="display: none;">
                            <div class="leaderboard-section">
                                <h4 id="leaderboard-header">Leaderboard</h4>
                                <hr>
                                <label for="gameID">Enter the Game ID:</label>
                                <input type="text" placeholder="" id="gameID" value="${lab.Variable.gameID}">
                                <button type="button" id="leaderboardSubmitBtn" class="primary" style="margin:10px" aria-label="Submit Game ID">Submit</button>
                                <br>
                                <span style="display: inline;">Your Player Name Is: </span><h3 id="player-name-display" style="display: inline;" aria-live="polite">${lab.Variable.playerName ? lab.Variable.playerName : ''}</h3>
                                <div id="leaderboard-error" aria-live="assertive"></div>
                            </div>
                        </div>
                    `);
                } else {
                    if (debug) { console.log("Leaderboard: Appending Leaderboard section to existing Challenge Labs tab"); }
                    challengeLabsContent.find('.leaderboard-section').remove(); // Remove existing section to avoid duplicates
                    challengeLabsContent.append(`
                        <div class="leaderboard-section">
                            <h4 id="leaderboard-header">Leaderboard</h4>
                            <hr>
                            <label for="gameID">Enter the Game ID:</label>
                            <input type="text" placeholder="" id="gameID" value="${lab.Variable.gameID}">
                            <button type="button" id="leaderboardSubmitBtn" class="primary" style="margin:10px" aria-label="Submit Game ID">Submit</button>
                            <br>
                            <span style="display: inline;">Your Player Name Is: </span><h3 id="player-name-display" style="display: inline;" aria-live="polite">${lab.Variable.playerName ? lab.Variable.playerName : ''}</h3>
                            <div id="leaderboard-error" aria-live="assertive"></div>
                        </div>
                    `);
                }
                // Convert gameID to uppercase on input
                $('#gameID').on('input', function() {
                    this.value = this.value.toUpperCase();
                });
                // Add submit button listener
                $('#leaderboardSubmitBtn').on('click', function() {
                    initPlayer();
                });
                // Initialize tab switching
                initializeTabSwitching();
                // Ensure default tab is preserved
                let defaultTab = $('.tabHeading.selected');
                if (defaultTab.length > 0) {
                    if (debug) { console.log(`Leaderboard: Preserving default tab - ${defaultTab.data('target')}`); }
                    $('.tab').css('display', 'none');
                    $(`#${defaultTab.data('target')}`).css('display', 'block');
                } else {
                    if (debug) { console.log("Leaderboard: No default tab found, using first tab"); }
                    $('.tabHeading').first().addClass('selected').attr('aria-selected', 'true').attr('tabindex', '0');
                    $('.tab').css('display', 'none');
                    $('.tab').first().css('display', 'block');
                }
            }
        } else {
            if (debug) { console.log("Leaderboard: Skipping initialization - editorWrapper present or Leaderboard variable not set"); }
        }
    }
  
    // Delay initialization until DOM is ready
    $(document).ready(function() {
        initializeLeaderboard();
    });
}
