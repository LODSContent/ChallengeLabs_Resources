// Code for mode switching
function modeSwitch() {
  try {modeSwitchSelected = $('[data-name="LabMode"] option:selected').first().text().toLowerCase()} catch (err) {modeSwitchSelected = null}
  if (modeSwitchSelected == 'guided') {
    //try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced").show();} catch (err) {}
    try {
      $('select[data-name="ShowGuided"] option[value="Yes"]').prop('selected', true)
      $('select[data-name="ShowGuided"]').trigger("change");            
    } catch (err) {}
    try {
      $('select[data-name="ShowAdvanced"] option[value="Yes"]').prop('selected', true)
      $('select[data-name="ShowAdvanced"]').trigger("change"); 
    } catch (err) {}
    try {
      $('select[data-name="ShowActivity"] option[value="Yes"]').prop('selected', true)
      $('select[data-name="ShowActivity"]').trigger("change");            
    } catch (err) {}
    } else if (modeSwitchSelected == 'advanced') {
    //try {$(".knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowAdvanced").show();} catch (err) {}
    //try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .ShowGuided").hide();} catch (err) {}
    try {
      $('select[data-name="ShowGuided"] option[value="No"]').prop('selected', true)
      $('select[data-name="ShowGuided"]').trigger("change");            
    } catch (err) {}
    try {
      $('select[data-name="ShowAdvanced"] option[value="Yes"]').prop('selected', true)
      $('select[data-name="ShowAdvanced"]').trigger("change");    
    } catch (err) {}
    try {
      $('select[data-name="ShowActivity"] option[value="Yes"]').prop('selected', true)
      $('select[data-name="ShowActivity"]').trigger("change");       
    } catch (err) {}
    } else if (modeSwitchSelected == 'expert') {
    //try {$(".hint, .hint-icon, .hintLink, .hiddenItem, .HiddenItem, .hiddenitem, .knowledge, .know-icon, .knowledgeLink, .moreKnowledge, .ShowGuided, .ShowAdvanced").hide();} catch (err) {}
    try {
      $('select[data-name="ShowGuided"] option[value="No"]').prop('selected', true)
      $('select[data-name="ShowGuided"]').trigger("change");            
    } catch (err) {}
    try {
      $('select[data-name="ShowAdvanced"] option[value="No"]').prop('selected', true)
      $('select[data-name="ShowAdvanced"]').trigger("change"); 
    } catch (err) {}
    try {
      $('select[data-name="ShowActivity"] option[value="No"]').prop('selected', true)
      $('select[data-name="ShowActivity"]').trigger("change");          
    } catch (err) {}
    } 
}

// Timeout for creating the mode switch watchdog
//setTimeout(()=>{
  try {
    modeSwitchItems = $('[data-name="LabMode"]')
    for (i=0;i < modeSwitchItems.length;i++) {
      //modeSwitchItems.click(function(){modeSwitch();});
      listener = 'modeSwitchItems[' + i +'].addEventListener(\'click\',function(){modeSwitch();});'
      eval(listener);        
    }
  } catch(err) {};
//}, 2000);
// End code for mode switching
