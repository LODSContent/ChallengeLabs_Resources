/*
 * Script Name: Leaderboard.js
 * Authors: Mark Morgan
 * Version: 1.05
 * Date: August 13, 2025
 * Description: Posts scores to the MarcoScore leaderboard application, with case-insensitive game ID 
 *              handling (displayed in uppercase) and timeout management for server requests. The game ID 
 *              entry form is placed in a "Leaderboard" section under a "Challenge Labs" tab, with a 
 *              display for the server-generated player name and errors. Tab-switching logic ensures 
 *              visibility with a green underline on selection.
 */

if (typeof debug === 'undefined') { var debug = false; } // Ensure debug is defined
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
        var lab = JSON.parse($('[data-name="labVariables"]').val());
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
                        $('#player-name-display').html(`Your Player Name is: ${lab.Variable.playerName}`);
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
        var lab = JSON.parse($('[data-name="labVariables"]').val());
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
                        $('#player-name-display').html(`Your Player Name is: ${lab.Variable.playerName}`);
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
        // Get the current lab variables
        var lab = JSON.parse($('[data-name="labVariables"]').val());
        for (i = 0; i < lab.stepItems.length; i++) {
            // Find a match between the current array index and the passed step number
            if (lab.stepItems[i].stepNumber == step) {
                // Get the status of the item to find if it has already been clicked
                try {
                    clicked = lab.stepItems[i].clicked;
                } catch (e) {
                    clicked = '';
                }
                if (clicked == "False") {
                    if (debug) { console.log(`Leaderboard: Step ${step} not previously clicked, applying penalty`); }
                    // Add to the step penalty
                    lab.Variable.totalPenalty = parseInt(lab.Variable.totalPenalty) + parseInt(lab.Variable.stepPenalty);
                    var score = parseInt(lab.Variable.stepPenalty) * -1;
                    if (debug) { console.log(`Leaderboard: Calculated penalty score - ${score}`); }
                    // Send data to scoring service
                    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    postScore(score);
                    lab = JSON.parse($('[data-name="labVariables"]').val());
                    // Set clicked to True so we don't add again
                    lab.stepItems[i].clicked = "True";
                    if (debug) { console.log(`Leaderboard: Marked step ${step} as clicked`); }
                }
            }
        }
        if (debug) { console.log("Leaderboard: Saving updated lab variables after step click"); }
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
   
    // Handle script task scoring
    function getScriptTasks() {
        if (debug) { console.log("Leaderboard: Checking for completed script tasks"); }
        // Get the lab variables
        try {
            var lab = JSON.parse($('[data-name="labVariables"]').val());
        } catch (e) {
            if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
        }
        // Find all stepItem class elements and put them in an array
        var scriptTasks = $('[class="scriptTask pass"]').map(function() {
            return $(this).data("id");
        }).get();
        // Create an array to hold the scored task items
        var scoredTasks = [];
        if (lab.scriptTasks) {
            scoredTasks = lab.scriptTasks;
        }
        for (i = 0; i < scriptTasks.length; i++) {
            try {
                if (!scoredTasks.includes(parseInt(scriptTasks[i])) && scriptTasks[i] != "" && scriptTasks[i] != null) {
                    if (debug) { console.log(`Leaderboard: Found new scored task - ID ${scriptTasks[i]}`); }
                    scoredTasks.push(scriptTasks[i]);
                    var score = lab.Variable.scoreValue;
                    if (debug) { console.log(`Leaderboard: Calculated task score - ${score}`); }
                    // Send the score to the server
                    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    postScore(score);
                }
            } catch (e) {
                if (debug) { console.log(`Leaderboard: Error processing task ${scriptTasks[i]} - ${e.message}`); }
            }
        }
        // Save the scored tasks back to the lab object
        lab.scriptTasks = scoredTasks;
        if (debug) { console.log("Leaderboard: Saving updated lab variables with scored tasks"); }
        // Set labVariables to the current value of the lab object
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    }
   
    // Initialize leaderboard functionality
    function initializeLeaderboard() {
        if (debug) { console.log("Leaderboard: Starting initialization"); }
        if ($('[id="editorWrapper"]').length == 0 && getLabVariable('Leaderboard')) {
            if (debug) { console.log("Leaderboard: Editor wrapper not present and Leaderboard variable set, proceeding"); }
            // Watch for changes to the script results
            const attrObserver = new MutationObserver((mutations) => {
                if (debug) { console.log("Leaderboard: Detected DOM mutation for script tasks"); }
                mutations.forEach(mu => {
                    if (mu.type !== "attributes" && mu.attributeName !== "class") return;
                    getScriptTasks();
                });
            });
            const ELS_test = document.querySelectorAll(".scriptTask");
            if (debug) { console.log(`Leaderboard: Observing ${ELS_test.length} scriptTask elements`); }
            ELS_test.forEach(el => attrObserver.observe(el, { attributes: true }));
   
            // Get the lab variables
            try {
                var lab = JSON.parse($('[data-name="labVariables"]').val());
                if (debug) { console.log("Leaderboard: Successfully parsed lab variables"); }
            } catch (e) {
                if (debug) { console.log(`Leaderboard: Error parsing lab variables - ${e.message}`); }
            }
           
            // Find all stepItem class elements and put them in an array
            foundSteps = $('[class^="stepItem"], .hint > details, .know-icon > summary, .hint-icon > summary, .moreKnowledge');
            var stepItems = [];
            for (i = 0; i < foundSteps.length; i++) {
                foundSteps[0].setAttribute('itemNumber', i);
                var obj = {
                    stepNumber: i,
                    clicked: 'False'
                };
                stepItems.push(obj);
                listener = 'foundSteps[' + i + '].addEventListener(\'click\', function() { stepClicked(' + i + '); });';
                if (debug) { console.log(`Leaderboard: Adding click listener for step ${i}`); }
                eval(listener);
            }
            if (debug) { console.log(`Leaderboard: Registered ${stepItems.length} step items`); }
           
            // If no saved lab variables, establish a new lab object with defaults
            if (!lab) {
                if (debug) { console.log("Leaderboard: No lab variables found, setting defaults"); }
                // Defaults for variables
                let debugVar = getLabVariable('debug');
                if (!debugVar) { debugVar = "False"; }
                let serverType = 'marcoscore'; // Only support marcoscore
                let serverAddress = 'marcoscore.cyberjunk.com'; // Hardcoded
                let gameID = getLabVariable('GameID');
                if (!gameID) { gameID = ""; }
                else { gameID = gameID.toUpperCase(); } // Normalize default gameID
                let playerName = getLabVariable('PlayerName');
                if (!playerName) { playerName = ""; }
                let stepPenalty = getLabVariable('StepPenalty');
                if (!stepPenalty) { stepPenalty = 100; }
                let totalPenalty = getLabVariable('TotalPenalty');
                if (!totalPenalty) { totalPenalty = 0; }
                let scoreValue = getLabVariable('ScoreValue');
                if (!scoreValue) { scoreValue = 0; }
                let totalScore = getLabVariable('TotalScore');
                if (!totalScore) { totalScore = 0; }
                let leaderboard = getLabVariable('Leaderboard');
                if (!leaderboard) { leaderboard = "False"; }
                // Creating a labVariables object
                var labVariables = {
                    debug: debugVar,
                    serverType: serverType,
                    serverAddress: serverAddress,
                    gameID: gameID,
                    playerName: playerName,
                    stepPenalty: stepPenalty,
                    totalPenalty: totalPenalty,
                    scoreValue: scoreValue,
                    totalScore: totalScore,
                    leaderboard: leaderboard
                };
                // Creating a lab object to store everything
                var lab = {
                    Variable: labVariables,
                    stepItems: stepItems
                };
                if (debug) { console.log("Leaderboard: Default lab variables set"); }
            }
           
            // Save the lab object
            if (debug) { console.log("Leaderboard: Saving initial lab variables"); }
            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
   
            // Add or update Challenge Labs tab
            if (lab.Variable.leaderboard != 'False') {
                if (debug) { console.log("Leaderboard: Preparing to add Challenge Labs tab"); }
                let tabHolder = $('#tabHolder');
                let challengeLabsTab = $('[data-target="challengeLabsTab"]');
                let nextTabId = tabHolder.find('.tabHeading').length; // Next ID after existing tabs
                if (challengeLabsTab.length === 0) {
                    if (debug) { console.log("Leaderboard: Creating new Challenge Labs tab"); }
                    tabHolder.append(`
                        <a tabindex="-1" class="tabHeading tab-heading primary-color-border" aria-selected="false" role="tab" aria-label="Challenge Labs" data-target="challengeLabsTab" data-id="${nextTabId}">Challenge Labs</a>
                    `);
                }
                // Add or update Leaderboard section in Challenge Labs tab
                let challengeLabsContent = $('#challengeLabsTab');
                if (challengeLabsContent.length === 0) {
                    if (debug) { console.log("Leaderboard: Creating Challenge Labs tab content"); }
                    $('.tabs').append(`
                        <div id="challengeLabsTab" class="tab tab-content zoomable" style="display: none;">
                            <div class="leaderboard-section">
                                <h4>Leaderboard</h4>
                                <hr>
                                <label for="gameID">Enter the Game ID:</label>
                                <input type="text" placeholder="" id="gameID" value="${lab.Variable.gameID}">
                                <button type="button" id="leaderboardSubmitBtn" class="primary" style="margin:10px">Submit</button>
                                <div id="player-name-display">${lab.Variable.playerName ? `Your Player Name is: ${lab.Variable.playerName}` : ''}</div>
                                <div id="leaderboard-error"></div>
                            </div>
                        </div>
                    `);
                } else {
                    if (debug) { console.log("Leaderboard: Appending Leaderboard section to existing Challenge Labs tab"); }
                    challengeLabsContent.find('.leaderboard-section').remove(); // Remove existing section to avoid duplicates
                    challengeLabsContent.append(`
                        <div class="leaderboard-section">
                            <h4>Leaderboard</h4>
                            <hr>
                            <label for="gameID">Enter the Game ID:</label>
                            <input type="text" placeholder="" id="gameID" value="${lab.Variable.gameID}">
                            <button type="button" id="leaderboardSubmitBtn" class="primary" style="margin:10px">Submit</button>
                            <div id="player-name-display">${lab.Variable.playerName ? `Your Player Name is: ${lab.Variable.playerName}` : ''}</div>
                            <div id="leaderboard-error"></div>
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
                // Trigger click on Challenge Labs tab if newly created
                if (challengeLabsTab.length === 0) {
                    if (debug) { console.log("Leaderboard: Triggering click on Challenge Labs tab"); }
                    $('[data-target="challengeLabsTab"]').click();
                }
                // Ensure tab content visibility
                if (debug) { console.log("Leaderboard: Ensuring Challenge Labs tab visibility"); }
                $('.tab').css('display', 'none');
                $('#challengeLabsTab').css('display', 'block');
                $('.tabHeading').removeClass('selected').attr('aria-selected', 'false').attr('tabindex', '-1');
                $('[data-target="challengeLabsTab"]').addClass('selected').attr('aria-selected', 'true').attr('tabindex', '0');
            }
        } else {
            if (debug) { console.log("Leaderboard: Skipping initialization - editorWrapper present or Leaderboard variable not set"); }
        }
    }
   
    initializeLeaderboard();
}
