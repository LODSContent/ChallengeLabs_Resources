
AI instructions:

Use the Markdown template below to format the structure of the lab instructions. 

Use the Overview section from the template as the Introduction. Preserve the [challenge-title] and [overview] markers, but edit the content as appropriate. Do not add any content other than comments before the first !INSTRUCTIONS include and challenge-title entry. Do not add any header markers or introductory text to the first page other than what should be included with the challenge-title and overview markers.

Make sure to preserve all !INSTRUCTIONS entries by formatting them with !INSTRUCTIONS immediately followed by an empty square bracket, followed by the content in parenthesis.

The topics provided will each be a requirement. Within each requirement should be 3 or more tasks. Each individual task should be followed by a corresponding "Hint" as a "Show Guided" item that details the steps involved in a task and a corresponding "Knowledge" as a "Show Advanced" item with a link to vendor documentation related to the same task. If there are 3 tasks, there should be 3 Guided and Advanced items, one beneath each task. Do not label the Tasks as Tasks.

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
