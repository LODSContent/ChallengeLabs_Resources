function handleToggles (){
  // ShowToggle
  try {showToggle = $('select[data-name="ShowToggle"]').val().toLowerCase();} catch (err) {showToggle = null}
  // ShowHints
  try {showHints = $('select[data-name="ShowHints"]').val().toLowerCase();} catch (err) {showHints = null}
  // ShowGuided
  try {showGuided = $('select[data-name="ShowGuided"]').val().toLowerCase();} catch (err) {showGuided = null}
  // ShowAdvanced
  try {showAdvanced = $('select[data-name="ShowAdvanced"]').val().toLowerCase();} catch (err) {showAdvanced = null}
  // ShowHints = yes or missing
  if (showHints == null || showHints !== 'no') {
    try {$('input.checkMode').attr('checked', true);} catch (err) {}
    if (showToggle == 'yes') {
      if (showGuided == 'yes') {  
        try {
          $('select[data-name="ShowGuided"] option[value="Yes"]').prop('selected', true)
          $('select[data-name="ShowGuided"]').trigger("change");               
        } catch (err) {}
      }
      if (showAdvanced == 'yes') {  
        try {
          $('select[data-name="ShowAdvanced"] option[value="Yes"]').prop('selected', true)
          $('select[data-name="ShowAdvanced"]').trigger("change");       
        } catch (err) {}
      }
    }
  }
  // ShowHints = no 
  else {
    try {$('input.checkMode').removeAttr('checked');} catch (err) {}
    try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced").hide();} catch (err) {}
    if (showToggle == 'yes') {
      if (showGuided == 'yes') {  
        try {
          $('select[data-name="ShowGuided"] option[value="No"]').prop('selected', true)
          $('select[data-name="ShowGuided"]').trigger("change");            
        } catch (err) {}
      }
      if (showAdvanced == 'yes') {  
        try {
          $('select[data-name="ShowAdvanced"] option[value="No"]').prop('selected', true)
          $('select[data-name="ShowAdvanced"]').trigger("change");        
        } catch (err) {}
      }
    }
  }

  //ShowToggle = no
  if (showToggle != null && showToggle == 'no') {
    try {$('.hint-toggle, [data-name="ShowHints"]').remove();} catch (err) {}
  }
  // ShowToggle = yes or missing
  else {
    $('body').on('click', 'input.checkMode', function () {
      // Is checkbox checked?
      if ($(this).is(':checked')) {
        $('input.checkMode').prop("checked", true);
        try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced").show();} catch (err) {}     
        // Is this the editor?
        if(document.querySelector('link[href^="/Css/EditInstructions.css"]') == null ){
          try {
            $('select[data-name="ShowHints"] option[value="Yes"]').prop('selected', true)
            $('select[data-name="ShowHints"]').trigger("change");  
          } catch (err) {}
          if (showToggle == 'yes') { 
            if (showGuided == 'yes') {             
              try {
                $('select[data-name="ShowGuided"] option[value="Yes"]').prop('selected', true)
                $('select[data-name="ShowGuided"]').trigger("change");               
              } catch (err) {}
            }
            if (showAdvanced == 'yes') { 
              try {
                $('select[data-name="ShowAdvanced"] option[value="Yes"]').prop('selected', true)
                $('select[data-name="ShowAdvanced"]').trigger("change");    
              } catch (err) {}
            }
          }
        }
      } else {
        try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced").hide();} catch (err) {}
        try {$('[data-variable-name="ShowGuided"]').hide();} catch (err) {}
        try {$('[data-variable-name="ShowAdvanced"]').hide();} catch (err) {}
        try {$('input.checkMode').prop("checked", false);} catch (err) {}
        if (document.querySelector('link[href^="/Css/EditInstructions.css"]') == null){
          try {
            $('select[data-name="ShowHints"] option[value="No"]').prop('selected', true)
            $('select[data-name="ShowHints"]').trigger("change");
          } catch (err) {}
          if (showToggle == 'yes') {
            if (showGuided == 'yes') { 
              try {
                $('select[data-name="ShowGuided"] option[value="No"]').prop('selected', true)
                $('select[data-name="ShowGuided"]').trigger("change");            
              } catch (err) {}                
            }
            if (showAdvanced == 'yes') { 
              try {
                $('select[data-name="ShowAdvanced"] option[value="No"]').prop('selected', true)
                $('select[data-name="ShowAdvanced"]').trigger("change");            
              } catch (err) {}
            }
          }
        }
      }
    });
  }
}

// Timeout based toggle handling
setTimeout(()=>{
  handleToggles();
}, 750);
