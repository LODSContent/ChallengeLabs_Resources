// Runs at the end of the lab report
if (debug) { console.log("Starting end-of-lab report generation"); }
document.querySelector("body").style.display = "none"; // Blank screen initially

try {
    // Configuration and data retrieval
    const autoTranslateStatus = getAutoTranslateStatus();
    const labLanguageCode = getLabLanguageCode();
    const languageFileUrl = getLanguageFileUrl(autoTranslateStatus, labLanguageCode);
    if (debug) { console.log(`AutoTranslate: ${autoTranslateStatus}, Language Code: ${labLanguageCode}, URL: ${languageFileUrl}`); }

    // Load and evaluate language file synchronously
    const scriptBody = loadScriptSync(languageFileUrl);
    eval(scriptBody); // Executes language file content
    const strings = window.strings; // Capture flavor text
    if (debug) { console.log("Language file loaded and evaluated, strings captured"); }

    // Parse report data
    const examData = parseReport();
    if (debug) { console.log("Report parsed:", examData); }

    // Assign summary color
    const colorOption = strings.summary.find(option => 
        option.maxScore >= examData.skillometerScore && option.minScore <= examData.skillometerScore
    ) || strings.summary[0]; // Fallback to first option
    examData.summaryColor = colorOption.color;
    if (debug) { console.log(`Assigned summary color: ${examData.summaryColor}`); }

    // Generate and apply report HTML
    document.querySelector("body").innerHTML = generateReport(examData, strings);
    if (debug) { console.log("Report HTML generated and applied"); }

    // Load jQuery Knob library and configure skillometer
    $.getScript("https://cdnjs.cloudflare.com/ajax/libs/jQuery-Knob/1.2.13/jquery.knob.min.js", () => {
        $(".dial").knob({
            min: 0,
            max: 100,
            readOnly: true,
            angleArc: 240,
            angleOffset: -120,
            fgColor: examData.summaryColor,
            inputColor: examData.summaryColor,
            width: 300,
            height: 240,
            thickness: ".35",
            format: value => `${value}%`
        });
        if (debug) { console.log("jQuery Knob library loaded and skillometer configured"); }
    });

    // Reveal report with delay
    setTimeout(() => {
        document.querySelector('body.end-of-lab-report')?.setAttribute('style', 'display:block !important');
        if (debug) { console.log("Report revealed after 1-second delay"); }
    }, 1000);

} catch (error) {
    console.error("Report generation failed:", error); // Keep error logging always on
    // Reveal standard report on failure
    document.querySelector('body.end-of-lab-report')?.setAttribute('style', 'display:block !important');
    if (debug) { console.log("Standard report revealed due to error"); }
}

// Helper Functions

function getAutoTranslateStatus() {
    return $('select[data-name="AutoTranslate"]').val()?.toLowerCase() || null;
}

function getLabLanguageCode() {
    return document.documentElement.lang || "en-US";
}

function getLanguageFileUrl(autoTranslateStatus, labLanguageCode) {
    const baseUrl = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/LanguageFiles/CLabsEOL-";
    return (autoTranslateStatus === 'no' || autoTranslateStatus === null)
        ? `${baseUrl}${labLanguageCode}.js`
        : `${baseUrl}ML.js`;
}

function loadScriptSync(url) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url, false); // Synchronous
    xhr.send();
    if (xhr.status !== 200) {
        throw new Error(`Failed to load script ${url}: HTTP ${xhr.status}`);
    }
    return xhr.responseText;
}

function parseReport() {
    const examData = {
        labName: getElementText(".labName"),
        labSeriesName: getElementText(".labSeriesName"),
        labInstanceId: getElementText(".labInstanceId"),
        duration: getElementText(".timeSpent"),
        expectedDuration: `${getElementText(".labProfileDurationMinutes")} minutes`,
        totalAchievedScore: 0,
        maxScore: 0,
        activities: [],
        assessments: { preScore: null, preMax: null, postScore: null, postMax: null }
    };

    const matchPreAssessment = /pre[ -]*assessment/gi;
    const matchPostAssessment = /post[ -]*assessment/gi;

    document.querySelectorAll(".activityGroupResult").forEach(activity => {
        const title = getElementText(".activityGroupName", activity);
        const scoreString = getElementText(".activityGroupScore", activity);
        const [numerator, denominator] = parseScoreFraction(scoreString);
        const percentage = parsePercentage(scoreString);

        if (matchPreAssessment.test(title)) {
            examData.assessments.preScore = `${numerator}/${denominator}`;
        } else if (matchPostAssessment.test(title)) {
            examData.assessments.postScore = `${numerator}/${denominator}`;
        } else {
            examData.totalAchievedScore += numerator;
            examData.maxScore += denominator;
            examData.activities.push({ title, score: percentage });
        }
    });

    examData.skillometerScore = Math.round((examData.totalAchievedScore / examData.maxScore) * 100) || 0;
    return examData;
}

function getElementText(selector, context = document) {
    return context.querySelector(selector)?.innerHTML || "";
}

function parseScoreFraction(scoreString) {
    const fraction = scoreString.match(/: (\d+\/\d+)/)?.[1] || "0/0";
    return fraction.split('/').map(Number);
}

function parsePercentage(scoreString) {
    const percentage = scoreString.match(/\d+%$/)?.[0] || "0%";
    return parseInt(percentage);
}

function assignText(type, score, strings) {
    if (!strings) {
        if (debug) { console.log("No strings available"); }
        return "";
    }

    const options = (type === "summaryHeader" || type === "summaryMessage")
        ? strings.summary
        : strings.activities;

    const match = options.find(option => 
        option.maxScore >= score && option.minScore <= score
    ) || options[0]; // Fallback to first option

    const key = type === "summaryHeader" ? "headings" : type === "summaryMessage" ? "captions" : "messages";
    const items = match[key] || [];
    return items[Math.floor(Math.random() * items.length)] || "";
}

function generateReport(examData, strings) {
    const { skillometerScore, summaryColor, activities } = examData;
    const summaryHeader = assignText("summaryHeader", skillometerScore, strings);
    const summaryMessage = assignText("summaryMessage", skillometerScore, strings);

    activities.forEach(activity => {
        activity.feedback = assignText("message", activity.score, strings);
    });

    let content = `
        <div id="report-container">
            <div id="report-body">
                <div id="print-container">
                    <a id="print-icon" onclick="print();">${strings.elements.print}</a>
                </div>
                <div class="report-section">
                    <h1 id="report-header">${summaryHeader}</h1>
                </div>
                <div class="report-section">
                    <h2 id="report-summary" style="color: ${summaryColor}">${summaryMessage}</h2>
                    <div id="report-skillometer">
                        <input type="text" value="${skillometerScore}" class="dial">
                    </div>
                </div>`;

    if (activities.some(activity => activity.score === 100)) {
        content += `
            <div class="report-section excelled">
                <h2 class="report-section-title">${strings.elements.excelled}</h2>
                <ul class="activities">
                    ${activities
                        .filter(activity => activity.score === 100)
                        .map(activity => `
                            <li>
                                <span class="report-activity-title">${activity.title}</span><br>
                                <span class="report-activity-feedback">${activity.feedback}</span>
                            </li>
                        `).join('')}
                </ul>
            </div>`;
    }

    if (activities.some(activity => activity.score < 100)) {
        content += `
            <div class="report-section growth">
                <h2 class="report-section-title">${strings.elements.growth}</h2>
                <ul class="activities">
                    ${activities
                        .filter(activity => activity.score < 100)
                        .map(activity => `
                            <li class="${activity.score > 0 ? 'partial' : 'none'}">
                                <span class="report-activity-title">${activity.title}</span><br>
                                <span class="report-activity-feedback">${activity.feedback}</span>
                            </li>
                        `).join('')}
                </ul>
            </div>`;
    }

    content += `
        <div class="report-section assessments">
            ${(examData.assessments.preScore || examData.assessments.postScore) 
                ? `<h2 class="report-section-title">${strings.elements.title}</h2>` : ''}
            ${examData.assessments.preScore ? `<div class="report-assessment"><span>Pre-Assessment: <b>${examData.assessments.preScore}</b></span></div>` : ''}
            ${examData.assessments.postScore ? `<div class="report-assessment"><span>Post-Assessment: <b>${examData.assessments.postScore}</b></span></div>` : ''}
        </div>
    </div>`;

    const key = window.location.pathname.split('/').pop();
    content += `
        <a href="https://labondemand.com/Evaluation/Submit/${key}" id="evaluation">
            <button type="button" class="primary">Challenge Labs Feedback ></button>
        </a>
    </div>`;

    return content;
}

function getColor() {
    if (document.querySelector('link[href^="/Css/Dark.css"]')) {
        document.querySelector('h2#report-summary')?.classList.add('dark');
    }
}
