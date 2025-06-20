// This script should be placed in the "Instructions Script" portion of a Skillable Theme. It will load each of the listed modular javascript files.

const debug = ['true', 'yes'].includes($('.variable[data-name="debug"]').text()?.toLowerCase());
//const debug = true;
if (debug) { console.log("Debug is on."); }

const labClientScripts = [
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/LabModeSwitch.js",
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/LabNotification.js",
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/ToggleHandler.js",
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/AutoTranslate.js",
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/Leaderboard.js"
];

const EOLReportScripts = [
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/EOLReport.js",
    "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ThemeFiles/AutoTranslate.js"
];

function loadScripts(urls) {
    const statusDiv = document.getElementById('status');
    for (const [index, url] of urls.entries()) {
        let retries = 5;
        let success = false;

        while (retries > 0 && !success) {
            try {
                const xhr = new XMLHttpRequest();
                xhr.open("GET", url, false);
                xhr.send();

                if (xhr.status === 200) {
                    eval(xhr.responseText);
                    if (debug) { console.log(`Loaded: ${url}`); }
                    success = true;
                } else {
                    throw new Error(`HTTP ${xhr.status}`);
                }
            } catch (error) {
                retries--;
                console.error(`Failed to load ${url}: ${error}. Retries left: ${retries}`);
                if (retries === 0) {
                    console.error(`Exhausted retries for ${url}`);
                }
            }
        }
    }
}

if (window.location.pathname.indexOf("ExamResult") < 0) {
    setTimeout(()=>{
        if (debug) { console.log("Loading Lab Client scripts."); }
        loadScripts(labClientScripts);
    }, 2000);
} else {
    setTimeout(()=>{
        if (debug) { console.log("Loading EOL report scripts."); }
        loadScripts(EOLReportScripts);
    }, 1000);
}
