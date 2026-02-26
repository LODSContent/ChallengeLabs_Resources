
AI instructions:

Use the Markdown template below to format the structure of the lab instructions. 

Use the Overview section from the template as the Introduction. Preserve the [challenge-title] and [overview] markers, but edit the content as appropriate. Do not add any content other than comments before the first !INSTRUCTIONS include and challenge-title entry. Do not add any markdown headers # or introductory text to the first page other than what should be included with the challenge-title and overview markers.

Make sure to preserve all !INSTRUCTIONS entries by formatting them with !INSTRUCTIONS immediately followed by an empty square bracket, followed by the content in parenthesis.

The topics provided will each be a requirement. Within each requirement should be 3 or more tasks. The tasks should be brief statements of what needs to be done within the environment without provided the step-by-step details. You will need to provide details that the student would not know, like the names of items to be created, or quantities, sizes etc.

Provide tables, images and codeblocks as needed for clarity in performing the task.

Each individual task should be followed by a corresponding "Hint" as a "Show Guided" item that details the steps involved in a task and a corresponding "Knowledge" as a "Show Advanced" item with a link to vendor documentation related to the same task. If there are 3 tasks, there should be 3 Guided and Advanced items, one beneath each task. Do not label the Tasks as Tasks.

Inside the tasks, the steps should be formatted as a markdown bulleted list. Add tables, images and codeblocks as needed for clarity.

Do not use numbering on any tasks or steps. The numbers in this template are just for reference.

The "Overview" section should be formatted EXACTLY as it is shown below, but updated with the particulars for this lab.

If we are converting an existing lab that already has some of this structure (Overview, tasks, steps, summary), make sure to preserve the verbiage and order of the existing content, while adding the additional markdown structure and conten to align with this template format.


Below is the markdown template:

<!-- Current Challenge Lab Template v4 - as of - 10/14/2025 -->

<!-- Begin Overview section -->

!INSTRUCTIONS[](https://raw.githubusercontent.com//LODSContent/Challenge-V3-Framework/main/Templates/Sections/Intro.md)

>[challenge-title]: Challenge Title Here

>[overview]: 
>
>You are a @lab.Variable(GlobalDeveloper) at @lab.Variable(GlobalCompany), a company that needs to... First, you will [REQUIREMENT 1]. Next, you will [REQUIREMENT 2], and then you will [REQUIREMENT 3]. Finally, you will [REQUIREMENT 4].
>
>

<!-- End Overview section -->
===
<!-- Begin Requirement 1 section -->

# Requirement 1

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Toggle.md) 

- Task 1.

**Developer note:(remove)** *Hint items are used in Guided labs to provide detailed instructions to complete a task and will be hidden when hints are off.*

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expand this hint for guidance on...
>
> There must be at least one blank line before the expandable content.
>
> Provide detailed steps to complete the task here...
>
:::

**Developer note:(remove)** *Knowledge items are used in Advanced labs to provide links to official vendor documentation and will be hidden when hints are off.*

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [using Windows system restore](https://support.microsoft.com/en-us/windows/use-system-restore-a5ae3ed9-07c4-fd56-45ee-096777ecd14e "using Windows system restore").
:::

**Developer note:(remove)** *For Knowledge items used as Advanced Hints where you cannot find appropriate vendor documentation, create a link to an appropriate search query. The words in the link must be concatenated with a plus (+) symbol with no spaces. This should be a last resort and should only be used when official vendor documentation or other legitimate references are not available.*

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Research [Windows 11 startup folder location](https://google.com/search?q=windows+11+startup+folder+location "Windows 11 startup folder location")
:::

>[!help] Help items are useful for information that realates to using the lab environment or performing a task that is unique to the lab setup. Using these elements can help to break up the hint and knowledge items visually. These items will always be displayed and should not reveal details intended to be suppressed in Advanced or Expert labs.

- Task 2.

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

>[!Alert] Alert items should be used whenever there is something that needs attention at this point in the lab. It could be something that is often missed, a message on the screen that should be ignored or anything else of importance. Using these elements can help to break up the hint and knowledge items visually. These items will always be displayed and should not reveal details intended to be suppressed in Advanced or Expert labs.

- Task 3.

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Click for more information").
:::


>[!note] Notes are a great for additional information about some aspect of this task in the lab or the topic in general. Using these elements can help to break up the hint and knowledge items visually. These items will always be displayed and should not reveal details intended to be suppressed in Advanced or Expert labs.


:::ShowActivity(ShowActivity=Yes)
## Check your work

@lab.ActivityGroup(requirement1)
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)

<!-- End Requirement 1 section -->
===
<!-- Begin Requirement 2 section -->

# Requirement 2

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Toggle.md) 

- Task 1.

:::ShowGuided(ShowGuided=Yes) 
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

- Task 2.

- Task 3.

:::ShowActivity(ShowActivity=Yes)
## Check your work

@lab.ActivityGroup(requirement2)
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)

<!-- End Requirement 2 section -->
===
<!-- Begin Requirement 3 section -->

# Requirement 3

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Toggle.md) 

- Task 1.

:::ShowGuided(ShowGuided=Yes) 
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

- Task 2.

- Task 3.

:::ShowActivity(ShowActivity=Yes)
## Check your work

@lab.ActivityGroup(requirement3)
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)

<!-- End Requirement 3 section -->
===
<!-- Begin Summary section -->

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Summary2.md)

>[recap]:
>Congratulations, you have completed the **CHALLENGE LAB TITLE?** Challenge Lab.
>
>You have accomplished the following:
>
>- Past tense list of requirements.

>[next-steps]:

<!-- A lab list will be generated from GitHub using the Series variable with a value of the Lab number prefix. (Example: AZ900-001 will have a Series variable value of AZ900) -->

<!-- End Summary Section -->

<!-- Begin: Requirement 1, Script 1 -->

```PowerShell
# The script template below should be used for any labs that involve the validation of lab tasks for a cloud platform like AWS or Azure or for Windows Clients and Servers running on the Skillable platform.

<#
   Title: <Title>
   Description: Brief summary of what the script does.
   Target: <Target - Cloud Platform, Custom or VM Name>
   Version: <YYYY.MM.DD> - Template.v4.0
#>

# Set default return value
$result = $false

# Debug toggle
$scriptDebug = '@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True'
if ($scriptDebug) { $ErrorActionPreference="Continue"; Write-Output "Debug mode is enabled." }

# Main function body for all validation code
function main {
    # Modify the code below to suit the needs of the validation being performed.
    # The scripting environment has $ErrorActionPreference = "Stop" by default.
    # Only use try/catch inside the main routine for something that is expected to fail and should not exit main.
    # There is a global try/catch at the end of the script that will handle error suppression for terminating errors.

    If ($scriptDebug) {Write-Output "Begin main routine."}

    # Parameters: Modify these to match the requirements of the lab environment
    $file = 'C:\LabFiles\SomeFileName.txt'
    $queryString = '*string to find in file*'
   
    # Add the commands for your scenario here
    $fileContent = [string](Get-Content $file)
    if ($scriptDebug -and $fileContent) {Write-Output "Found file."}

    # Perform your validation testing here
    if ($fileContent -like $queryString) {
        $result = $true
        if ($scriptDebug) {Write-Output "Validation successful."}
    } else {
        $result = $false
        if ($scriptDebug) {Write-Output "Validation failed."}
    }

    if ($scriptDebug) {Write-Output "End main routine."}
    
    # Return the result from the main function
    return $Result
}

# Run the main routine - When debugging, no Try/Catch is used. Any Errors or debug messages will display.
if ($scriptDebug) {
    $result = main
} else {
    try {
        $result = main
    } catch {
        $result = $false
    }
}

return $result
```
<!-- End: Requirement 1, Script 1 -->

<!-- Begin: Requirement 1, Script 2 -->

```bash
# The following script template should be used for any validations that involve a linux machine or a container running on the Skillable platform

#!/bin/bash
# Title: Lab Environment Validation
# Description: Validates lab environment by checking file content
# Target: Linux VM or Container Name
# Version: 2025.10.22 - Template.v4.0

# Validation parameters
# The file we check for and the string to query for:
file="$HOME/nmap.txt"
queryString="Starting Nmap"

# Set default return value (0 for success, 1 for failure in Bash)
result=1

# Debug toggle (checking environment variable LAB_DEBUG)
if [[ "@lab.Variable(debug)" == "Yes" || "@lab.Variable(debug)" == "True" || "@lab.Variable(Debug)" == "Yes" || "@lab.Variable(Debug)" == "True" ]]; then
    scriptDebug=1
    echo "Debug mode is enabled."
else
    scriptDebug=0
fi

# Main function body for all validation code
main() {
if [ $scriptDebug -eq 1 ]; then
        echo "Begin main routine."
    fi

    # Check if file exists
    if [ ! -f "$file" ]; then
        if [ $scriptDebug -eq 1 ]; then
            echo "File not found: $file"
        fi
        return 1
    fi

    # Read file content
    fileContent=$(cat "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        if [ $scriptDebug -eq 1 ]; then
            echo "Failed to read file: $file"
        fi
        return 1
    fi

    if [ $scriptDebug -eq 1 ] && [ -n "$fileContent" ]; then
        echo "Found file."
    fi

    # Perform validation testing
    if echo "$fileContent" | grep -q "$queryString"; then
        result=0
        if [ $scriptDebug -eq 1 ]; then
            echo "Validation successful"
        fi
    else
        result=1
        if [ $scriptDebug -eq 1 ]; then
            echo "Validation failed"
        fi
    fi

    if [ $scriptDebug -eq 1 ]; then
        echo "End main routine."
    fi

    return $result
}
# Run the main routine
if [ $scriptDebug -eq 1 ]; then
    main
    result=$?
else
    main 2>/dev/null
    result=$?
fi

if [ $result -eq 0 ]; then
    echo true
else
    echo false
fi
```

<!-- End: Requirement 1, Script 2 -->

<!-- Begin: Requirement 1, Script 3 -->
Code block here...
<!-- End: Requirement 1, Script 3 -->

<!-- Begin: Requirement 2, Script 1 -->
Etc...
<!-- End: Requirement 2, Script 1 -->
