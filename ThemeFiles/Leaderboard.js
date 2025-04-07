/*
 * Script Name: Leaderboard.js
 * Authors: Mark Morgan
 * Version: 1.00
 * Date: April 6, 2025
 * Description: Posts scores to an online leaderboard application. 
 */

// begin shared functions

// Show popupMsg
function showPopupMsg(popupName,html,action,page,showNow){
  // See if there is an existing popupMsg and ignore creating if it is already there
  if ($('#' + popupName).length == 0) {
    // Establish the node that the popupMsg will be placed after
    var node = document.getElementsByClassName(page)[0];
    // Create the new element for the popupMsg
    var popupMsg = document.createElement("div");
    // Class name for the popup
    //popupMsg.className = "popupMsg";
    popupMsg.className = "notification primary-color-border";
    // ID for the popup
    popupMsg.id = popupName;
    // Custom style
    popupMsg.style = 'bottom: 100px;right: 15px; position: fixed;';
    // Custom message to display on Page 0
    popupMsg.innerHTML = html;
    // Add the submit button
    var submitBtn = document.createElement("button");
    submitBtn.type = "button";
    submitBtn.className = "primary";
    submitBtn.id = popupName + "Btn";
    submitBtn.innerText = 'Submit';
    submitBtn.style = "margin:10px"
    //popupMsg.appendChild(submitBtn);           
    // Add the close button
    var closeBtn = document.createElement("button");
    closeBtn.type = "button";
    closeBtn.className = "primary";
    closeBtn.id = popupName + "CloseBtn";
    closeBtn.innerText = 'Close';
    closeBtn.style = "margin:10px"
    //popupMsg.appendChild(closeBtn);   
    // Add the popupMsg at the end of page0
    try {
      node.appendChild(popupMsg);
      $('#' + popupName + 'ButtonHolder')[0].append(submitBtn);
      $('#' + popupName + 'ButtonHolder')[0].append(closeBtn);                  
      // Build a command string with a variable inside the function
      var commandString = "$('#" + popupName + "Btn')[0].addEventListener('click',function(){" + action + ";});";
      // Execute the command string
      eval(commandString);
      // Add the close action
      commandString = "$('#' + popupName + 'CloseBtn')[0].addEventListener('click',function(){$('#' + popupName).hide();});";
      eval(commandString);
    } catch(err) {};         
  }
  // Show the popupMsg
  if (showNow) {
    $('#' + popupName).show();
  } else {
    $('#' + popupName).hide();
  }
}

// retrieve a lab variable listed in Markdown as a case-insensitive variable name
function getLabVariable(name) {
  let checkName = name.toLowerCase();
  return $('[data-name]').filter(function() {return $(this).attr('data-name').toLowerCase()== checkName}).val();
}

function setLabVariable(name,value) {
  $('[data-name="' + name + '"]').val(value).trigger("change");
}

// end shared functions

let leaderboard = getLabVariable('Leaderboard');
if (leaderboard.toLowerCase() == "true") {  

  // begin leaderboard lab code
  // initialize the player on the leaderboard
  function initPlayer() {
    var lab = JSON.parse($('[data-name="labVariables"]').val());
    lab.Variable.playerName = $('[name="playerName"]').val();
    lab.Variable.gameID = $('[name="gameID"]').val();
    //lab.Variable.serverAddress = $('[name="serverAddress"]').val()
    if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
      let leaderboardURL = 'https://keepthescore.com/api/' + lab.Variable.gameID + '/player/';
      let xhttp = new XMLHttpRequest();
      let json = JSON.stringify({
          "name": lab.Variable.playerName,
          "score": lab.Variable.totalScore,
          "team": null,
          "profile_image": null
      });
      xhttp.open("POST", leaderboardURL);
      xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
      xhttp.send(json);
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status >= 200 && this.status <= 299) {
          setTimeout(function() {
            lab.Variable.playerID = (JSON.parse(xhttp.response)).player.id;
            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");	
          }, 1000);
        }
      }
    } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
      // This command will not work until the server uses SSL/TLS
      let leaderboardURL = 'http://' + lab.Variable.serverAddress + ':8083/api/scores/' + lab.Variable.playerID;
      let xhttp = new XMLHttpRequest();
      let json = JSON.stringify({
          "name": lab.Variable.playerName,
          "value": lab.Variable.totalScore,
          "category": lab.Variable.gameID
      });
      xhttp.open("POST", leaderboardURL);
      xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
      xhttp.send(json);
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status >= 200 && this.status <= 299) {
          setTimeout(function() {
            lab.Variable.playerID = (JSON.parse(xhttp.response))._id;
            $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
          }, 1000);
        }
      }      
    } else if (lab.Variable.leaderboard.toLowerCase() === "marcoscore" && lab.Variable.gameID.length > 1) {
        //let leaderboardURL = 'https://marcoscore.cyberjunk.com/submit'; // Our endpoint, assuming port 443
        let leaderboardURL = 'https://localhost/submit'; // Our endpoint, assuming port 443
        let xhttp = new XMLHttpRequest();
        let json = JSON.stringify({
            "gameID": lab.Variable.gameID,          // Game ID from your variable
            "playerName": lab.Variable.playerName,  // Can be blank
            "scoreAdd": lab.Variable.totalScore     // Total score as the amount to add
        });
        
        xhttp.open("POST", leaderboardURL);
        xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
        xhttp.send(json);
        
        xhttp.onreadystatechange = function() {
            if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                let response = JSON.parse(xhttp.responseText);
                if (response.success && response.playerName) {
                    // If playerName was blank, update it with the server's generated name
                    if (!lab.Variable.playerName) {
                        lab.Variable.playerName = response.playerName;
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    }
                }
            }
        };
    }
    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
    $('#leaderboardPopup').hide();      
  }  
  
  // post a score to the leaderboard server
  function postScore(score) {
    var lab = JSON.parse($('[data-name="labVariables"]').val());
    if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
      let leaderboardURL = 'https://keepthescore.com/api/' + lab.Variable.gameID + '/score/';
      let xhttp = new XMLHttpRequest();
      let json = JSON.stringify({
          "player_id": lab.Variable.playerID,
          "score": score
      });
      xhttp.open("POST", leaderboardURL);
      xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
      xhttp.send(json);
    } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard" && lab.Variable.playerName.length > 1 && lab.Variable.gameID.length > 1) {
      // This command will not work until the server uses SSL/TLS
      let leaderboardURL = 'http://' + lab.Variable.serverAddress + ':8083/api/scores/' + lab.Variable.playerID;
      let xhttp = new XMLHttpRequest();
      let json = JSON.stringify({
          "name": lab.Variable.playerName,
          "value": score,
          "category": lab.Variable.gameID
      });
      xhttp.open("PUT", leaderboardURL);
      xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
      xhttp.send(json);
    } else if (lab.Variable.leaderboard.toLowerCase() === "marcoscore" && lab.Variable.gameID.length > 1) {
        //let leaderboardURL = 'https://marcoscore.cyberjunk.com/submit'; // Our endpoint, assuming port 443
        let leaderboardURL = 'https://localhost/submit'; // Our endpoint, assuming port 443
        let xhttp = new XMLHttpRequest();
        let json = JSON.stringify({
            "gameID": lab.Variable.gameID,          // Game ID from your variable
            "playerName": lab.Variable.playerName,  // Can be blank
            "scoreAdd": score                       // Score to add (assuming 'score' is defined)
        });
        
        xhttp.open("POST", leaderboardURL);         // Changed from PUT to POST
        xhttp.setRequestHeader('Content-type', 'application/json; charset=utf-8');
        xhttp.send(json);
        
        xhttp.onreadystatechange = function() {
            if (this.readyState === 4 && this.status >= 200 && this.status <= 299) {
                let response = JSON.parse(xhttp.responseText);
                if (response.success && response.playerName) {
                    // If playerName was blank, update it with the server's generated name
                    if (!lab.Variable.playerName) {
                        lab.Variable.playerName = response.playerName;
                        $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
                    }
                }
            }
        };
    }
    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");    
  }
  
  function stepClicked(step) {
    // Get the current lab variables
    var lab = JSON.parse($('[data-name="labVariables"]').val());
    for (i=0;i < lab.stepItems.length;i++) {
      // Find a match between the current array index and the passed step number
      if (lab.stepItems[i].stepNumber == step) {
        // Get the status of the item to find if it has already been clicked
        try {clicked = lab.stepItems[i].clicked} catch (e) {clicked = ''}
        if (clicked == "False") {				
          // Add to the step penalty
          lab.Variable.totalPenalty = parseInt(lab.Variable.totalPenalty) + parseInt(lab.Variable.stepPenalty);
          if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" || lab.Variable.leaderboard.toLowerCase() == "marcoscore") {
            var score = parseInt(lab.Variable.stepPenalty) * -1;
          } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard") {
            var score = parseInt(lab.Variable.totalScore) - parseInt(lab.Variable.totalPenalty);
          }
          // Send data to scoring service:
          $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
          postScore(score);
          lab = JSON.parse($('[data-name="labVariables"]').val());            
          // Set clicked to True so we don't add again
          lab.stepItems[i].clicked = "True";
        }
      }
    }
    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
  }
  
  function getScriptTasks() {
    // Get the lab variables from the @lab.EssayTextBox(labVariables) markdown item that must be somewhere in the lab (but can be hidden)
    try {var lab = JSON.parse($('[data-name="labVariables"]').val());} catch (e) {}      
    // Find all stepItem class elements and put them in an array. These must be named with a class of stepItem-# (where # is the unique number of the element)
    var scriptTasks = $('[class="scriptTask pass"]').map(function() {
      return $(this).data("id");
    }).get();
    // Create an array to hold the scored task items
    var scoredTasks = [];
    if (lab.scriptTasks) {scoredTasks = lab.scriptTasks}
    for (i=0;i < scriptTasks.length;i++) {
      try {
        if (!scoredTasks.includes(parseInt(scriptTasks[i])) && scriptTasks[i] != "" && scriptTasks[i] != null) {
          scoredTasks.push(scriptTasks[i]);
          if (lab.Variable.leaderboard.toLowerCase() == "keepthescore" || lab.Variable.leaderboard.toLowerCase() == "marcoscore") {
            var score = lab.Variable.scoreValue;
          } else if (lab.Variable.leaderboard.toLowerCase() == "leaderboard") {
            lab.Variable.totalScore = parseInt(lab.Variable.totalScore) + parseInt(lab.Variable.scoreValue);
            var score =  parseInt(lab.Variable.totalScore);
          }
          // Send the score to the server
          $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");
          postScore(score);
        }
      } catch (e) {} 
    }
    // Save the scored tasks back to the lab object
    lab.scriptTasks = scoredTasks;
    // Set labVariables to the current value of the lab object
    $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");		
  }
  
  function initializeLeaderboard() {
    if ($('[id="editorWrapper"]').length == 0 && getLabVariable('Leaderboard')) {
      // Watch for changes to the script results
      const attrObserver = new MutationObserver((mutations) => {
        mutations.forEach(mu => {
          if (mu.type !== "attributes" && mu.attributeName !== "class") return;
          getScriptTasks();
        });
      });      
      const ELS_test = document.querySelectorAll(".scriptTask");
      ELS_test.forEach(el => attrObserver.observe(el, {attributes: true}));
  
      // Get the lab variables from the @lab.EssayTextBox(labVariables) markdown item that must be somewhere in the lab (but can be hidden)
      try {var lab = JSON.parse($('[data-name="labVariables"]').val());} catch (e) {}
      
      // Find all stepItem class elements and put them in an array. These must be named with a class of stepItem-# (where # is the unique number of the element)
      foundSteps = $('[class^="stepItem"],.hint > details,.know-icon > summary,.hint-icon > summary, .moreKnowledge');
      var stepItems = [];
      for (i=0;i < foundSteps.length;i++) {
        foundSteps[0].setAttribute('itemNumber',i)
        var obj = {
          stepNumber: i,
          clicked: 'False'
        }
        stepItems.push(obj);
        listener = 'foundSteps[' + i +'].addEventListener(\'click\',function(){stepClicked(' + i + ');});'
        eval(listener);
      }
      // If no saved lab variables, establish a new lab object with defaults
      if (!lab) {
        // Defaults for the following can be set as variables in the lab. Must be in the lab as an @lab.TextBox() variables (but can be hidden) 
        let debug = getLabVariable('debug');
        if (!debug) {debug = "False"};
        let serverType = getLabVariable('ServerType');
        if (!serverType) {serverType = "marcoscore"};
        let serverAddress = getLabVariable('ServerAddress');
        if (!serverAddress) {serverAddress = "https://marcoscore.cyberjunk.com"};              
        let gameID = getLabVariable('GameID');
        if (!gameID) {gameID = ""};
        let playerName = getLabVariable('PlayerName');
        if (!playerName) {playerName = ""};
        let playerID = getLabVariable('PlayerID');
        if (!playerID) {playerID = ""}                      
        let stepPenalty = getLabVariable('StepPenalty');
        if (!stepPenalty) {stepPenalty = 100};
        let totalPenalty = getLabVariable('TotalPenalty');
        if (!totalPenalty) {totalPenalty = 0};
        let scoreValue = getLabVariable('ScoreValue');
        if (!scoreValue) {scoreValue = 0};        
        let totalScore = getLabVariable('TotalScore');
        if (!totalScore) {totalScore = 0};               
        let leaderboard = getLabVariable('Leaderboard');
        if (!leaderboard) {leaderboard = "False"};                
        // Creating a labVariables object
        var labVariables = {
          debug: debug,
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
        }
        // Creating a lab object to store everything
        var lab = {
          Variable: labVariables,
          stepItems: stepItems
        }
      }
      
      // Save the lab object to an @lab.EssayTextBox(labVariables) markdown item that must be somewhere in the lab (but can be hidden)
      $('[data-name="labVariables"]').val(JSON.stringify(lab)).trigger("change");	
  
      // Show the leaderboardPopup if variable is set
      if (lab.Variable.leaderboard != 'False') {
  
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
               
        // showLeaderboardPopup();
        showPopupMsg('leaderboardPopup',html,'initPlayer()',"instructions-client",true);
      }
    }
  }
  
  initializeLeaderboard();
}
