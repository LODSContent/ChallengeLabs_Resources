// Begin Blockquote styling code (Matching alternate icons to platform icons.)
  // Function to get a current CSS style value
  function get_style_rule_value(selector, style, match)
  {
    for (var i = 0; i < document.styleSheets.length; i++)
    {
      var mysheet = document.styleSheets[i];
      try {
        var myrules = mysheet.cssRules ? mysheet.cssRules : mysheet.rules;

        for (var j = 0; j < myrules.length; j++)
        {
            if (match == 'exact') {
                if (myrules[j].selectorText && myrules[j].selectorText.toLowerCase() === selector && myrules[j].style[style] != undefined)
                {
                    //console.log('Selector: ' + selector + ' - Sheet: ' + i + ' - Rule: ' + j + ' - Value: ' + myrules[j].style[style]);            
                    return myrules[j].style[style];
                }
            } else {
                if (myrules[j].selectorText && myrules[j].selectorText.toLowerCase().indexOf(selector) >= 0 && myrules[j].style[style] != undefined)
                {
                    //console.log('Selector: ' + selector + ' - Sheet: ' + i + ' - Rule: ' + j + ' - Value: ' + myrules[j].style[style]);            
                    return myrules[j].style[style];
                }            
            }

        }
      } catch (e) {}
    }
  }

  // Function to convert an RGB color value to hex
  function convertRGB(rgbColor) {
    try {
      if (rgbColor == undefined) {
        //console.log('No color to convert.')
        return;
      };
      var a = rgbColor.split("(")[1].split(")")[0];
      a = a.split(",");
      var b = a.map(function(x){            //For each array element
          x = parseInt(x).toString(16);     //Convert to a base16 string
          return (x.length==1) ? "0"+x : x; //Add zero if we get only one character
      });
      return "#"+b.join("");   
    } catch (e) {}
  }

  function setColors() {
    // Get the current value of the --blockquote-background CSS variable
    var blockquoteBackgroundEnable = getComputedStyle(document.body).getPropertyValue('--blockquote-background-enable');
    // Get the current value of the --blockquote-background-alpha CSS variable
    var blockquoteBackgroundAlpha = getComputedStyle(document.body).getPropertyValue('--blockquote-background-alpha');
    if (blockquoteBackgroundAlpha == undefined) {blockquoteBackgroundAlpha = '10';}
    // Get the current value of the --blockquote-shadow CSS variable
    var blockquoteShadowEnable = getComputedStyle(document.body).getPropertyValue('--blockquote-shadow-enable');
    // Get the current value of the --blockquote-shadow-color CSS variable
    var blockquoteShadowColor = getComputedStyle(document.body).getPropertyValue('--blockquote-shadow-color');

    // Get the root CSS section for variables
    var r = document.querySelector(':root');

    // Get the colors of the standard alert,help,hint and note blocks
    const icons = ["alert","help","hint","note"]
    icons.forEach((icon) => {
        color = get_style_rule_value('blockquote.' + icon,'border-color','exact');
        try {
            color = convertRGB(color);
            // Set the border and icon color
            if (color != undefined) {
              r.style.setProperty('--' + icon + '-color', color);
              if (blockquoteBackgroundEnable == 'true') {
                  r.style.setProperty('--' + icon + '-bg-color',color + blockquoteBackgroundAlpha);    
              } else if (blockquoteBackgroundEnable == 'false') {
                  r.style.setProperty('--' + icon + '-bg-color','transparent');
              } else {
                  r.style.setProperty('--' + icon + '-bg-color',blockquoteBackgroundEnable);
              }
            }
            // Set the shadow color
            if (blockquoteShadowEnable != undefined) {
              if (blockquoteShadowEnable.indexOf(icon) >= 0 || blockquoteShadowEnable == 'true') {
                  r.style.setProperty('--' + icon + '-shadow',blockquoteShadowColor);
              } else {
                  r.style.setProperty('--' + icon + '-shadow', 'none');
              }
            }        
        } catch (e) {}
    });

    // Get the color primary-color used for knowledge items
    color = get_style_rule_value('.primary-color','color','partial');
    try {
        color = convertRGB(color);
        r.style.setProperty('--knowledge-color', color);
        if (blockquoteBackgroundEnable == 'true') {
            r.style.setProperty('--knowledge-bg-color',color + blockquoteBackgroundAlpha);    
        } else if (blockquoteBackgroundEnable == 'false') {
            r.style.setProperty('--knowledge-bg-color','transparent');
        } else {
            r.style.setProperty('--knowledge-bg-color',blockquoteBackgroundEnable);
        }    

        // Set the shadow color
        if (blockquoteShadowEnable.indexOf('knowledge') >= 0 || blockquoteShadowEnable == 'true') {
            r.style.setProperty('--knowledge-shadow',blockquoteShadowColor);
        } else {
            r.style.setProperty('--knowledge-shadow', 'none');
        }            
    } catch (e) {}
    
    // Get the accent-border and background used for standard no-icon blockquotes
    color = get_style_rule_value('.accent-border','border-color','partial');
    bgColor = get_style_rule_value('.accent-background','background-color','partial')
    try {
        color = convertRGB(color);
        bgcolor = convertRGB(bgColor);
        r.style.setProperty('--blockquote-color', color);
        if (blockquoteBackgroundEnable == 'true') {
            r.style.setProperty('--blockquote-bg-color',color + blockquoteBackgroundAlpha);    
        } else if (blockquoteBackgroundEnable == 'false') {
            r.style.setProperty('--blockquote-bg-color',bgColor);
        } else {
            r.style.setProperty('--blockquote-bg-color',blockquoteBackgroundEnable);
        }   

        // Set the shadow color
        if (blockquoteShadowEnable.indexOf('blockquote') >= 0 || blockquoteShadowEnable == 'true') {
            r.style.setProperty('--blockquote-shadow',blockquoteShadowColor);
        } else {
            r.style.setProperty('--blockquote-shadow', 'none');
        }            
    } catch (e) {}

    // Get the accent-border used for standard no-icon expandable blockquotes
    color = get_style_rule_value('.primary-color','color','partial');
    try {
        color = convertRGB(color);
        r.style.setProperty('--expandable-blockquote-color', color);
        if (blockquoteBackgroundEnable == 'true') {
            r.style.setProperty('--expandable-blockquote-bg-color',color + blockquoteBackgroundAlpha);    
        } else if (blockquoteBackgroundEnable == 'false') {
            r.style.setProperty('--expandable-blockquote-bg-color','transparent');
        } else {
            r.style.setProperty('--expandable-blockquote-bg-color',blockquoteBackgroundEnable);
        }     

        // Set the shadow color
        if (blockquoteShadowEnable.indexOf('expandable-blockquote') >= 0 || blockquoteShadowEnable == 'true') {
            r.style.setProperty('--expandable-blockquote-shadow',blockquoteShadowColor);
        } else {
            r.style.setProperty('--expandable-blockquote-shadow', 'none');
        }                    
    } catch (e) {}

    
    // Get the primary button color to set additional elements like the Hint slider
    color = get_style_rule_value('button.primary','background-color','partial');
    try {
        color = convertRGB(color); 
        r.style.setProperty('--button-primary-color', color);           
    } catch (e) {}

  }    

  // Call the setColors function
  try {
    setColors();
  } catch (err) {}

  // Timeout for creating the setColors "observer" watching for changes.
  setTimeout(()=>{
    try {
      // Watch for changes to the colors in the lab viewer
      const observer = new MutationObserver((mutations) => {
        mutations.forEach(mu => {
            if (mu.type === "attributes") {
                setColors();
            }
        });
      });      
      const element = document.getElementById('settings-menu');
      observer.observe(element, {attributes: true});  
    } catch(err) {};

    /*
    try {
      // Watch for changes to the colors in the theme editor
      const observer2 = new MutationObserver((mutations) => {
        mutations.forEach(mu => {
            if (mu.type === "attributes") {
                setColors();
            }
        });
      });      
      const element = document.getElementById('colorModeSettingsContainer');
      observer2.observe(element, {attributes: true});   
    } catch(err) {};
    */
  }, 2000);

  // End - Blockquote styling code
