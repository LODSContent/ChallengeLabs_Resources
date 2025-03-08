// Begin lab Notification code 
// Function to display an lab Notification message on Page 0 based upon lab content
function labNotifications(){
  // Get custom messages to display on Page 0
  let uri = 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/LabNotifications/labNotifications-dev.json';
  let xhttp = new XMLHttpRequest();
  xhttp.open("GET", uri, false);
  xhttp.send();
  var messageObj = JSON.parse(xhttp.responseText);

  // Loop through the messages
  for (let i = 0; i < messageObj.messages.length; i++) {
    // Extract the current message in the array
    message = messageObj.messages[i];

    // Set the innerHTML for the new element
    innerHTML = `<details><summary>${message.summary}</summary><br>${message.details}</details>`;
    
    // String to search for in the preview or client window (using Regex syntax, but \ needs to be \\)
    queryString = message.queryString;
    var regex = new RegExp(queryString, "is");
    
    // Get the date values
    const now = new Date();
    if (!message.startDate) {var startDate = new Date('1/1/1999')} 
    else {var startDate = new Date(message.startDate)}
    if (!message.endDate) {var endDate = new Date('1/1/2999')}
    else {var endDate = new Date(message.endDate)};    
    
    // Get the HTML from the Client or the Preview depending on where we are
    try {bodyText = document.getElementById("labClient").innerHTML} catch(err) {
      bodyText = document.getElementById("previewWrapper").innerHTML
    }
    
    // See if there is an existing lab Notification and ignore creating if it is already there
    labNotificationId = document.getElementById(message.id);
    
    // Display the header and the message if conditions are met
    if ((bodyText.search(regex) != -1) && !labNotificationId && startDate < now && endDate > now) {
      // Establish the node that the lab Notification will be placed after
      var node = document.getElementById("page0");

      // Create the header of the notes section
      headerId = document.getElementById("labNotificationsHeader");
      if (!headerId) {
        var header = document.createElement("h2");
        header.innerHTML = "Lab Notifications";
        header.className = "blink4 flash";
        header.id = "labNotificationsHeader"
        try {node.appendChild(header)} catch(err) {};
      }
      // Create the new element for the lab Notification
      var labNotification = document.createElement("blockquote");
      labNotification.className = message.type;
      labNotification.title = "Lab Notification"
      labNotification.id = message.id;
      labNotification.innerHTML = innerHTML;
      // Add the lab Notification at the end of page0
      try {node.appendChild(labNotification)} catch(err) {};      
    }
  }
}
  
// Timeout for running the lab Notification function
//setTimeout(()=>{
  try {
    labNotifications();
  } catch(err) {};
//}, 2000);
// End lab Notification code
