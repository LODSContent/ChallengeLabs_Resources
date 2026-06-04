AI instructions:

Use the Markdown template below to format the structure of the lab instructions.

*New labs:
Use the Overview section from the template as the Introduction. Preserve the [challenge-title] and [overview] markers, but edit the content as appropriate. Do not add any content other than comments before the first !INSTRUCTIONS include and challenge-title entry. Do not add any markdown headers # or introductory text to the first page other than what should be included with the challenge-title and overview markers.

Make sure to preserve all !INSTRUCTIONS entries by formatting them with !INSTRUCTIONS immediately followed by an empty square bracket, followed by the content in parenthesis.

The topics provided will each be a requirement. Within each requirement should be 3 or more tasks. The tasks should be brief statements of what needs to be done within the environment without provided the step-by-step details. You will need to provide details that the student would not know, like the names of items to be created, or quantities, sizes etc.

Provide tables, images and codeblocks as needed for clarity in performing the task.

Each individual task should be followed by a corresponding "Hint" as a "Show Guided" item that details the steps involved in a task and a corresponding "Knowledge" as a "Show Advanced" item with a link to vendor documentation related to the same task. If there are 3 tasks, there should be 3 Guided and Advanced items, one beneath each task. Do not label the Tasks as Tasks.

Inside the tasks, the steps should be formatted as a markdown bulleted list. Add tables, images and codeblocks as needed for clarity.

Do not use numbering on any tasks or steps. The numbers in this template are just for reference.

The "Overview" section should be formatted EXACTLY as it is shown below, but updated with the particulars for this lab.

Short lines of code to be typed in a command window or editor should be wrapped in single backticks.

Long code blocks should be wrapped in triple back ticks.

If there is a validation that can only be perfomed visually by the student, use a markdown element like the following to prompt for a value that will be validated in a PowerShell validation script:

Enter the name of the first service in the list on the screen into the following textbox:

@lab.TextBox(Req1Check1)


*Conversions:
If we are converting an existing lab that already has some of this structure (Overview, tasks, steps, summary), make sure to preserve the verbiage and order of the existing content, while adding the additional markdown structure and conten to align with this template format.

During a conversion, if you encounter any image links like this: !IMAGEData source page Make sure that the descriptor in the square brackets [] is a true descriptor and not just a repeat of the file name from the parenthesis (). Infer from the content and steps prior to the image link what that descriptor should be. If there is already a good descriptor, do not modify it.
Items to be typed by the student should be wrapped in ++ markers (our lab "Copy Text").

*You will notice in the existing overview, there is a token for GlobalAdministrator and a token for GlobalCompany. Feel free to use these where appropriate in designing the narrative for each of the Requirements and Major tasks.

*Above the overview, replace the !INSTRUCTIONS[] entry with !INSTRUCTIONS[] followed by (https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Intro.md) on the same line with no spaces.

*Keep the existing >[challenge-title]: section.

*Keep the existing >[Overview]: section, but replace it with the following:
>[overview]:
Welcome to the Challenge Lab!Learn something new, validate your current skills or explore a preconfigured environment. Use the ***Select lab mode*** option above to choose how you would like to begin your journey.

*After that page break "===" below the overview, add a new page using the following format:
<!-- Begin Introduction section -->
!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Header.md) 
# Introduction
<Old overview>
:::ShowLearn(ShowLearn=Yes)
## Objectives
> <Objectives>

## Learn more about this lab: <challenge-title>
<Introduction>
:::
!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)
<!-- End Introduction section -->
===

*Replace <Old overview> with just the text from the old [overview] section, but without the [overview] and > symbols.

*Replace <Objectives> with a list of objectives that reflect the lab "Requirements". Preceed each line in the Objectives section with a > to make it a blockquote.

*After the <Objectives>, replace <Introduction> with a training document that provides verbose details on each of the topics covered in the requirements for the lab. Teach these topics as if they were not being covered later in a hands-on manner. Explain and teach the topics as if this were a stand-alone documentation on these topics. Provide as much detail as you can on each topic. Do not include any step-by-step instructions. Use well-formatted markdown interjected with some fancy markdown elements to make the content visually appealing. Use our custom >[!hint] >[!note] and >[!knowlege] sections to add interesting details to the documentation. (Look at the existing markdown for examples.) Be verbose. Make sure to cover all of the requirements and topics from the entire lab. Include a "References" section at the bottom with links to official vendor documentation.

*At the end of the <Introduction> section, but before the trailing ::: Add the following Skillable AI prompt, replacing <Title> with the title of the lab. Update the "<Detailed list of topics from this lab>" to help the AI set the context for the chat session.:  

<br>

----

<br>
ai-chat[<Title>] { placeholder:"Ask me questions to learn more...", messages:["Answer questions about <Detailed list of topics from this lab>. Act as an Instructor. Use technical language. I am a beginner."]}

*For each of the requirements, add a section for an introduction to the requirement based upon the Title of that Requirement and the tasks being performed in that requirement. Keep the existing title at the top of the section. The introduction does not need a separate title. Add the requirement introduction just below the !INSTRUCTIONS[] tag at the top of each requirement section. Use the same @lab.Variable values that are used in the main introduction. Wrap the requirement introduction in the following ShowLearn section:
:::ShowLearn(ShowLearn=Yes)
<Requirement introduction goes here.>
:::

*After the Introduction, add an HR and line break as follows:
---
<br>

*Replace the !INSTRUCTIONS[] entry containing Toggle.md at the top of each section, including the Introduction page, with !INSTRUCTIONS[] followed by (https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Header.md) on the same line with no spaces.

*Preserve all of the existing tasks in each requirement as they are. Do not remove or add any tasks or [+hint] items.

*For the individual tasks within the Requirement. Add an introduction to the task with a summary of what they are going to be doing. This introduction should occur just above the corresponding bullet. Keep existing bullets "-" in-place where they currently are in front of the individual tasks and do not place bullets in front of the :::ShowLearn sections. The title of the introduction does not need to contain the word Task:

*Do not include specifics about the names of things to be created. You can be specific about the services/resources/technologies being utilized. Add the section for the task just above the bullet for that task.

*The task introduction that you add should be placed within a section like below:
:::ShowLearn(ShowLearn=Yes)
<Task introduction goes here.>
:::

*At the end of each Requirement, add a section for multiple choice questions. Depending on the length of the Requirement Section and how many topics are covered generate from 3 to 10 questions. The questions will come from our own internal system using the "ShowMCQ" section below. Replace <Requirement Title> with the title of the current requirement. Update the "<Detailed list of topics from this Requirement>" to help the AI generate appropriate questions and responses. Add additional details to the list of topics for more granularity where needed. Update the "num_questions" value with a number from 3 to 10. This section should be placed just above the !INSTRUCTIONS[] tag at the bottom of each section and should look like the following:
:::ShowMCQ(ShowMCQ=Yes)
<br><br>
## Knowledge check
>[+]Section Quiz:
>
>ai-quiz[Section quiz]{"num_questions":5,"prompt":"Generate a set of questions based upon <Detailed list of topics from this requirement>. Act as if you are an instructor and I am a beginner."}
:::

*Replace the !INSTRUCTIONS[] entry at the bottom of each section, including the Introduction page,  with !INSTRUCTIONS[] followed by (https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md) on the same line with no spaces.

*In the "Summary" section, replace the !INSTRUCTIONS[] entry at the top of the section with !INSTRUCTIONS[] followed by (https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Summary.md) on the same line with no spaces. Update the "Congratulations" with a summary detailing what the student has just accomplished within the lab. Use the same format with the > symbols to keep the section in tact. Leave the "You have accomplished" section as-is with the list of requirements.


*Below is the full markdown template:

<!-- Current Challenge Lab Template v5 - as of - 05/18/2026 -->

<!-- Begin Overview section -->

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Intro.md)

>[challenge-title]: Challenge Title Here

>[overview]: 
>Welcome to the Challenge Lab! Learn something new, validate your current skills or explore a preconfigured environment. Use the ***Select lab mode*** option above to choose how you would like to begin your journey.

<!-- End Overview section -->
===
<!-- Begin Introduction section -->
!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)

# Introduction
>You are a @lab.Variable(GlobalDeveloper) at @lab.Variable(GlobalCompany), a company that needs to... First, you will [REQUIREMENT 1]. Next, you will [REQUIREMENT 2], and then you will [REQUIREMENT 3]. Finally, you will [REQUIREMENT 4].

:::ShowLearn(ShowLearn=Yes)
## Objectives
> Requirement 1 title
> Requirement 2 title
> Requirement 3 title
> etc...

## Learn more about this lab: <Lab Title>

### Requirement 1 topic header
<Detailed training information regarding Requirement 1.>

### Requirement 2 topic header
<Detailed training information regarding Requirement 2.>

### Requirement 3 title
<Detailed training information regarding Requirement 3.>

### etc...

<br>

----

<br>

ai-chat[<Title>] { placeholder:"Ask me questions to learn more...", messages:["Answer questions about <Detailed list of topics from this lab>. Act as an Instructor. Use technical language. I am a beginner."]}

:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)

<!-- End Introduction section -->
===
<!-- Begin Requirement 1 section -->

# Requirement 1

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Header.md) 

:::ShowLearn(ShowLearn=Yes)
<Requirement introduction goes here.>
:::

:::ShowLearn(ShowLearn=Yes)
### Task 1 title

<Introduction to Task 1>
:::

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

:::ShowLearn(ShowLearn=Yes)
### Task 2 title

<Introduction to Task 2>
:::

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

:::ShowLearn(ShowLearn=Yes)
### Task 3 title

<Introduction to Task 3>
:::

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

:::ShowMCQ(ShowMCQ=Yes)
<br><br>
## Knowledge check
>[+]Section Quiz:
>
>ai-quiz[Section quiz]{"model_id":1,"num_questions":5,"prompt":"Generate a set of questions based upon <Detailed list of topics from this requirement>. Act as if you are an instructor and I am a beginner."}
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)

<!-- End Requirement 1 section -->
===
<!-- Begin Requirement 2 section -->

# Requirement 2

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Header.md) 

:::ShowLearn(ShowLearn=Yes)
<Requirement introduction goes here.>
:::

:::ShowLearn(ShowLearn=Yes)
### Task 1 title

<Introduction to Task 1>
:::

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

:::ShowLearn(ShowLearn=Yes)
### Task 2 title

<Introduction to Task 2>
:::

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

:::ShowLearn(ShowLearn=Yes)
### Task 3 title

<Introduction to Task 3>
:::

- Task 3.

:::ShowGuided(ShowGuided=Yes) 
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

:::ShowActivity(ShowActivity=Yes)
## Check your work

@lab.ActivityGroup(requirement2)
:::

:::ShowMCQ(ShowMCQ=Yes)
<br><br>
## Knowledge check
>[+]Section Quiz:
>
>ai-quiz[Section quiz]{"model_id":1,"num_questions":5,"prompt":"Generate a set of questions based upon <Detailed list of topics from this requirement>. Act as if you are an instructor and I am a beginner."}
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)

<!-- End Requirement 2 section -->
===
<!-- Begin Requirement 3 section -->

# Requirement 3

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Header.md) 

:::ShowLearn(ShowLearn=Yes)
<Requirement introduction goes here.>
:::

:::ShowLearn(ShowLearn=Yes)
### Task 2 title

<Introduction to Task 2>
:::

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

:::ShowLearn(ShowLearn=Yes)
### Task 3 title

<Introduction to Task 3>
:::

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

- Task 3.


:::ShowGuided(ShowGuided=Yes) 
>[+hint] Expand this hint for guidance on...
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

:::ShowActivity(ShowActivity=Yes)
## Check your work

@lab.ActivityGroup(requirement3)
:::

:::ShowMCQ(ShowMCQ=Yes)
<br><br>
## Knowledge check
>[+]Section Quiz:
>
>ai-quiz[Section quiz]{"model_id":1,"num_questions":5,"prompt":"Generate a set of questions based upon <Detailed list of topics from this requirement>. Act as if you are an instructor and I am a beginner."}
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Footer.md)

<!-- End Requirement 3 section -->
===
<!-- Begin Summary section -->

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/Challenge-V5-Framework/Includes/Summary.md)

>[recap]:
>Congratulations, you have completed the **CHALLENGE LAB TITLE?** Challenge Lab.
>
>You have accomplished the following:
>
>- Past tense list of requirements.

>[next-steps]:

<!-- A lab list will be generated from GitHub using the Series variable with a value of the Lab number prefix. (Example: AZ900-001 will have a Series variable value of AZ900) -->
