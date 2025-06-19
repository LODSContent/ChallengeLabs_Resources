/*
* Script Name: Leaderboard.js
* Authors: Mark Morgan
* Version: 1.00
* Date: April 6, 2025
* Description: Posts scores to an online leaderboard application. 
*/

if (debug) { console.log("Leaderboard: Script is loading"); }

// begin shared functions

// Show popupMsg
function showPopupMsg(popupName, html, action, page, showNow) {
    if (debug) { console.log(`Leaderboard: Creating popup - ${popupName}`); }
    // See if there is an existing popupMsg and ignore creating if it is already there
    if ($('#' + popupName).length == 0) {
        if (debug) { console.log(`Leaderboard: No existing popup found for ${popupName}, proceeding to create`); }
        // Establish the node that the popupMsg will be placed after
        var node = document.getElementsByClassName(page)[0];
        // Create the new element for the popupMsg
        var popupMsg = document.createElement("div");
        // Class name for the popup
        popupMsg.className = "notification primary-color-border";
        // ID for the popup
        popupMsg.id = popupName;
        // Custom style
        popupMsg.style = 'bottom: 100px; right: 15px; position: fixed;';
        // Custom message to display on Page 0
        popupMsg.innerHTML = html;
        // Add the submit button
        var submitBtn = document.createElement("button");
        submitBtn.type = "button";
        submitBtn.className = "primary";
        submitBtn.id = popupName + "Btn";
        submitBtn.innerText = 'Submit';
        submitBtn.style = "margin:10px";
        // Add the close button
        var closeBtn = document.createElement("button");
        closeBtn.type = "button";
        closeBtn.className = "primary";
        closeBtn.id = popupName + "CloseBtn";
        closeBtn.innerText = 'Close';
        closeBtn.style = "margin:10px";
        // Add the popupMsg at the end of page0
        try {
            if (debug) { console.log(`Leaderboard: Appending popup ${popupName} to DOM`); }
            node.appendChild(popupMsg);
            $('#' + popupName + 'ButtonHolder')[0].append(submitBtn);
            $('#' + popupName + 'ButtonHolder')[0].append(closeBtn);                  
            // Build a command string with a variable inside the function
            var commandString = "$('#" + popupName + "Btn')[0].addEventListener('click', function() {" + action + ";});";
            if (debug) { console.log(`Leaderboard: Adding click event listener for ${popupName} submit button`); }
            // Execute the command string
            eval(commandString);
            // Add the close action
            commandString = "$('#' + popupName + 'CloseBtn')[0].addEventListener('click', function() {$('#' + popupName).hide();});";
            if (debug) { console.log(`Leaderboard: Adding click event listener for ${popupName} close button`); }
            eval(commandString);
        } catch (err) {
            if (debug) { console.log(`Leaderboard: Error appending popup ${popupName} - ${err.message}`); }
        };         
    }
    // Show the popupMsg
    if (showNow) {
        if (debug) { console.log(`Leaderboard: Showing popup ${popupName}`); }
        $('#' + popupName).show();
    } else {
        if (debug) { console.log(`Leaderboard: Hiding popup ${popupName}`); }
        $('#' + popupName).hide();
    }
}

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

// end shared functions

// begin leaderboard lab code
let leaderboard = getLabVariable('Leaderboard');
if (leaderboard == "True") {  
    if (debug) { console.log("Leaderboard: Leaderboard enabled, proceeding with initialization"); }
    
    // Initialize the player on the leaderboard
    function initPlayer() {
        if (debug) { console.log("Leaderboard: Initializing player"); }
        var lab = JSON.parse($('[data-name="labVariables"]').val());
        lab.Variable.playerName = $('[name="playerName"]').val();
        lab.Variable.gameID = $('[name="gameID"]').val();
        lab.Variable.serverAddress = $('[name="serverAddress"]').val();
        if (debug) { console.log(`Leaderboard: Player data - Name: ${lab.Variable.playerName}, GameID: ${lab.Variable.gameID}, Server: ${lab.Variable.serverAddress}`); }
        
        if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Initializing player for keepthescore"); }
            let leaderboardURL = 'https://keepthescore.com/api/' + lab.Variable.gameID + '/player/';
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "name": lab.Variable.playerName,
                "score": lab.Variable.totalScore,
                "team": null,
                "profile_image": null
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState == 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: keepthescore player initialization successful"); }
                    setTimeout(function() {
                        lab.Variable.playerID = (JSON.parse(xhttp.response)).player.id;
                        if (debug) { console.log(`Leaderboard: Updated playerID to ${lab.Variable.playerID}`); }
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");	
                    }, 1000);
                } else if (this.readyState == 4) {
                    if (debug) { console.log(`Leaderboard: keepthescore player initialization failed - Status: ${this.status}`); }
                }
            };
        } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Initializing player for leaderboard service"); }
            let leaderboardURL = 'http://' + lab.Variable.serverAddress + ':8083/api/scores/' + lab.Variable.playerID;
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "name": lab.Variable.playerName,
                "value": lab.Variable.totalScore,
                "category": lab.Variable.gameID
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState == 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: Leaderboard service player initialization successful"); }
                    setTimeout(function() {
                        lab.Variable.playerID = (JSON.parse(xhttp.response))._id;
                        if (debug) { console.log(`Leaderboard: Updated playerID to ${lab.Variable.playerID}`); }
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    }, 1000);
                } else if (this.readyState == 4) {
                    if (debug) { console.log(`Leaderboard: Leaderboard service player initialization failed - Status: ${this.status}`); }
                }
            };      
        } else if (lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Initializing player for marcoscore"); }
            let leaderboardURL = 'https://' + lab.Variable.serverAddress + '/submit';
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "gameID": lab.Variable.gameID,
                "playerName": lab.Variable.playerName,
                "scoreAdd": lab.Variable.totalScore
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: marcoscore player initialization successful"); }
                    let response = JSON.parse(xhttp.responseText);
                    if (response.success && response.playerName) {
                        if (debug) { console.log("Leaderboard: Received playerName from marcoscore response"); }
                        if (!lab.Variable.playerName) {
                            lab.Variable.playerName = response.playerName;
                            if (debug) { console.log(`Leaderboard: Updated playerName to ${lab.Variable.playerName}`); }
                            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                        }
                    }
                } else if (this.readyState === 4) {
                    if (debug) { console.log(`Leaderboard: marcoscore player initialization failed - Status: ${this.status}`); }
                }
            };
        }
        if (debug) { console.log("Leaderboard: Saving updated lab variables"); }
        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
        if (debug) { console.log("Leaderboard: Hiding leaderboard popup"); }
        $('#leaderboardPopup').hide();      
    }  
    
    // Post a score to the leaderboard server
    function postScore(score) {
        if (debug) { console.log(`Leaderboard: Posting score - ${score}`); }
        var lab = JSON.parse($('[data-name="labVariables"]').val());
        if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Posting score to keepthescore"); }
            let leaderboardURL = 'https://keepthescore.com/api/' + lab.Variable.gameID + '/score/';
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "player_id": lab.Variable.playerID,
                "score": score
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
        } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Posting score to leaderboard service"); }
            let leaderboardURL = 'http://' + lab.Variable.serverAddress + ':8083/api/scores/' + lab.Variable.playerID;
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "name": lab.Variable.playerName,
                "value": score,
                "category": lab.Variable.gameID
            });
            if (debug) { console.log(`Leaderboard: Sending PUT to ${leaderboardURL}`); }
            xhttp.open("PUT", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
        } else if (lab.Variable.gameID.length > 1) {
            if (debug) { console.log("Leaderboard: Posting score to marcoscore"); }
            let leaderboardURL = 'https://' + lab.Variable.serverAddress + '/submit';
            let xhttp = new XMLHttpRequest();
            let json = JSON.stringify({
                "gameID": lab.Variable.gameID,
                "playerName": lab.Variable.playerName,
                "scoreAdd": score
            });
            if (debug) { console.log(`Leaderboard: Sending POST to ${leaderboardURL}`); }
            xhttp.open("POST", leaderboardURL);
            xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
            xhttp.send(json);
            xhttp.onreadystatechange = function() {
                if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                    if (debug) { console.log("Leaderboard: marcoscore score post successful"); }
                    let response = JSON.parse(xhttp.responseText);
                    if (response.success && response.playerName) {
                        if (debug) { console.log("Leaderboard: Received playerName from marcoscore response"); }
                        if (!lab.Variable.playerName) {
                            lab.Variable.playerName = response.playerName;
                            if (debug) { console.log(`Leaderboard: Updated playerName to ${lab.Variable.playerName}`); }
                            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                        }
                    }
                } else if (this.readyState === 4) {
                    if (debug) { console.log(`Leaderboard: marcoscore score post failed - Status: ${this.status}`); }
                }
            };
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
                    if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" || lab.Variable.leaderboard.toLowerCase() == "marcoscore") {
                        var score = parseInt(lab.Variable.stepPenalty) * -1;
                    } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard") {
                        var score = parseInt(lab.Variable.totalScore) - parseInt(lab.Variable.totalPenalty);
                    }
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
                    if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" || lab.Variable.leaderboard.toLowerCase() == "marcoscore") {
                        var score = lab.Variable.scoreValue;
                    } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard") {
                        lab.Variable.totalScore = parseInt(lab.Variable.totalScore) + parseInt(lab.Variable.scoreValue);
                        var score = parseInt(lab.Variable.totalScore);
                    }
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
                let serverType = getLabVariable('ServerType');
                if (!serverType) { serverType = "marcoscore"; }
                let serverAddress = getLabVariable('ServerAddress');
                if (!serverAddress) { serverAddress = "https://marcoscore.cyberjunk.com"; }              
                let gameID = getLabVariable('GameID');
                if (!gameID) { gameID = ""; }
                let playerName = getLabVariable('PlayerName');
                if (!playerName) { playerName = ""; }
                let playerID = getLabVariable('PlayerID');
                if (!playerID) { playerID = ""; }                      
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
                    playerID: playerID,
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
    
            // Show the leaderboard popup if variable is set
            if (lab.Variable.leaderboard != 'False') {
                if (debug) { console.log("Leaderboard: Preparing to show leaderboard popup"); }
                console.log("Showing popup.");
                html = `
                    <div tabindex="0" aria-describedby="notificationContent0">
                    <span class="screen-reader-only">Alert</span>
                    <div class="notificationContentTopPadding"></div>
                    <div class="notificationContent" role="alert" id="notificationContent0">
                    <h4>This is a Skillable Team Challenge!</h4>
                    <hr>
                    <label for="playerName">Enter your Player or Team name:</label>
                    <input type="text" placeholder="" name="playerName" required>
                    <br><br>
                    <label for="gameID">Enter the Game ID:</label>
                    <input type="text" placeholder="" name="gameID" required>
                    <br><br>
                    <label for="serverAddress">Enter the server address:</label>
                    <input type="text" placeholder="" name="serverAddress" required>
                    <br><br>
                    <div id="leaderboardPopupButtonHolder" style="text-align:center"></div>          
                    </div>
                    </div>
                    <div class="closeNotification primary-color-icon" tabindex="0" aria-label="Close" title="Close">
                    </div>
                `;
                showPopupMsg('leaderboardPopup', html, 'initPlayer()', "instructions-client", true);
            }
        } else {
            if (debug) { console.log("Leaderboard: Skipping initialization - editorWrapper present or Leaderboard variable not set"); }
        }
    }
    
    initializeLeaderboard();
}
