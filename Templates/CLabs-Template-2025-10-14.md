<!-- Current Challenge Lab Template v4 - as of - 10/14/2025 -->

!INSTRUCTIONS[](https://raw.githubusercontent.com//LODSContent/Challenge-V3-Framework/main/Templates/Sections/Intro.md)

>[challenge-title]: Challenge Title Here

>[overview]: 
>
>You are a @lab.Variable(GlobalDeveloper) at @lab.Variable(GlobalCompany), a company that needs to... First, you will [REQUIREMENT 1]. Next, you will [REQUIREMENT 2], and then you will [REQUIREMENT 3]. Finally, you will [REQUIREMENT 4].
>
>

===
<!-- Sample Markdown Elements - Remove this section for production -->
# Markdown styles that can be used:

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Toggle.md) 

*(When the "Hints Enabled" toggle above is set to "No", all Hint and Knowledge items in the lab will be hidden. In addition, all ShowGuided and ShowAdvanced sections will be hidden.)*

In this section you will find the Markdown styles that we suggest using for Challenge Lab authoring. You can find additional help and syntax specific to the lab editor by using the **? - Help** menu option.

The lab editor follows most standard Markdown syntax rules beyond the lab editor customizations.

- Icon blocks will typically follow an associated task item that is listed as a bullet. All icon blocks are automatically indented one level. 
- Use the Standard icon blocks for short statements or small quantities of detail. 
- Use the Expandable icon blocks for details that should only be visible once expanded and for larger amounts of detail that would otherwise clutter the screen.

---

### Challenge Labs Activity Blocks and Sections
These blocks and sections will typically be found in each activity within a challenge lab. When the "Hints Enabled" slider is set to "No", these items will be hidden. This is a special configuration designed for the Challenge labs environment.

#### Hint Blocks

>[!Hint] This is a standard Hint block. Hints will be hidden when hints are off.

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expand this Hint for guidance on...
>
> There must be at least one blank line before the expandable content. 
>
> - Expandable hints are typically used for step-by-step style instructions.
>
> **Note**: All labs must include "Reviewer steps" that will allow a reviewer to complete the lab. Those steps should be included inside an Expandable Hint, like this one, wrapped in a Section with (ShowGuided=Yes). When the lab is in review, these steps can be made visible by setting a lab variable ShowSteps to True. For production, the ShowSteps variable can be removed or set to False.
>
> Hints will be hidden when hints are off.
>
:::

#### Knowledge block

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance").
>
> This Knowledge block will be hidden when the ShowAdvanced lab variable is set to "False" or when hints are off by either setting the ShowHints variable to "No" or by using the toggle in the lab..
> 
> If there is enough content, a Knowledge block will automatically be expandable.
> 
> Knowledge items are typically used to provide additional detail that may be useful in completing the lab, such as links to product or vendor documentation.
> 
> Knowledge items are hidden when hints are off.
>
> Knowledge items, like this one, wrapped in a Section with (ShowAdvanced=Yes) can be made visible by setting a lab variable ShowAdvanced to True. For Expert labs, the ShowAdvanced variable can be removed or set to False.
<!-- There MUST be a blank space here before the ::: end of section, or the Knowledge item will not be expandable. -->
:::

>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance").
> 
> This Knowledge item will be hidden when hints are off by either setting the ShowHints variable to "No" or by using the toggle in the lab.
>
> If there is enough content, a Knowledge block will automatically be expandable.
> 
> Knowledge items are typically used to provide additional detail that may be useful in completing the lab, such as links to product or vendor documentation.
>
> This knowledge item is not wrapped in a ShowAdvanced=Yes section and therefore will be unaffected by the ShowAdvanced setting.


<!-- Begin Guided item section  -->
:::ShowGuided(ShowGuided=Yes)
#### Guided items:
(Any item can be hidden by wrapping the markdown in a "ShowGuided" section. It will be hidden when hints are off or when the ShowGuided variable is set to False.)
<!-- Use for items that should be hidden when ShowGuided is disabled but are not included in hints/knowledge blocks.  -->
- Run the following command in a PowerShell session:

    ```powershell
    Get-Service

    Get-Service | Where Name -like *win* | Out-File .\WinServices.txt

    ```
:::
<!-- End Guided item section  -->


<!-- Begin Advanced item section  -->
:::ShowAdvanced(ShowAdvanced=Yes)
#### Advanced items:
(Any item can be hidden by wrapping the markdown in a "ShowAdvanced" section. It will be hidden when hints are off or when the ShowAdvanced variable is set to False.)
<!-- Use for items that should be hidden when ShowAdvanced is disabled but are not included in hints/knowledge blocks.  -->
>[+] For additional help, review the following video on how to create an S3 bucket:
>
!video[Creating an S3 bucket](https://lodmanuals.blob.core.windows.net/lms/SkillChallLabFiles/VirtualMachine%20and%20TypeText.mp4) 
>
:::
<!-- End Advanced item section  -->

---

### Additional Skillable Sections
These Skillable markdown items can be used to enhance a challenge lab with content that will be displayed at all times. Using Note, Help and Alert items can help call out detail within a lab and can serve to visually break up the wall of Hint and Knowledge items that would otherwise result.

#### Note blocks

>[!note] This is a standard Note block.

>[+note] Expand this Note for additional information about...
>
> Notes are typically used to call out something that be out of the ordinary in the lab environment, or that may not always be expected.
>
> There must be at least one blank line before the expandable content.
>

#### Help blocks

>[!help] This is a standard Help block.

>[+help] Expand this for additional Help about...
>
> Help items are typically used to assist with something in the lab environment such as logons, switching VMs, etc.
>
> There must be at least one blank line before the expandable content.
>

#### Alert blocks
>[!alert] This is a standard Alert block.

>[+alert] Expand this Alert for important details about...
>
> Alerts should be used to grab the student's attention for something very important that they should not miss.
>
> There must be at least one blank line before the expandable content.
>

---

### Standard Markdown Elements
The following markdown styles can be used to present tables, code blocks and images within the lab content.


#### Tables:    
(To indent the table, preceed it with a bulleted item, then indent the table itself. There must be a blank line following the bullet before the table.)

- Perform task (...) using details in the following table:

    |Property|Value| 
    |:--|:--| 
    |Property 1|**Value 1**| 
    |Property 2|**Value 2**|
    |Property 3|**Value 3**|
    |Property 4|**Value 4**|


#### Code blocks:    
(To indent the code block, preceed it with a bulleted item, then indent the content. There must be a blank line following the bullet before the code block.)

- Run the following command in a terminal session:

    ```bash
    code block
    ```

- Run the following command in a PowerShell session:

    ```PowerShell
    Get-Service
    Get-ChildItem
    ```

#### Inline code blocks:
Inline code blocks provide examples of code within a line of text that can be automatically typed within a VM or copied for pasting into the user's local console.

- Type the ```Get-Aduser -Identity 'User1'``` command to retrieve a user from Active Directory.

#### Type Text
Type text can be used to present text or commands that can be automatically typed within a VM.

- Type the +++Get-Aduser -Identity 'User1'+++ command to retrieve a user from Active Directory.

#### Copy Text
Type text can be used to present text or commands that can be copied and pasted into the user's local console, or for large quantities of text that can be copied and pasted into a Hyper-V VM with Enhanced Session Mode and Clipboard enabled.

- Copy the ++Get-Aduser -Identity 'User1'++ command to retrieve a user from Active Directory.

#### Images:

- Indent an image following a bullet.

    !IMAGE[AdvancedLogo.png](AdvancedLogo.png)

>[+note] Images can also be included inside an expandable block.
>
> There must be at least one blank line before the expandable content. 
>
> Images can be included inside the icon blocks. Provide at least one blank line (or 4 spaces at the end of the line) before the image:
>
>!IMAGE[AdvancedLogo.png](AdvancedLogo.png)


#### Videos:
This is an example of an "iconless" block which can be used if none of the standard icons apply to the content of this section. However, videos can be embedded within any of the standard icon sections as well.

(Add the following video at the beginning of labs that use VMs.)

>[+]Review the following video on logging in to a Virtual Machine (VM)
>
>!video[Logging in to  a Virtual Machine (VM)](https://lodmanuals.blob.core.windows.net/lms/SkillChallLabFiles/VirtualMachine%20and%20TypeText.mp4) 
>

<br>
(When absolutely necessary, you can add more spacing between elements with one or more HTML br tags.)
<br>
<br>

---

### Samples of markdown icons with content.
These examples show how lists, images, tables and code blocks can be embedded within an expandable section in the style used for a typical Challenge lab.


- Task 1.

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expandable section with a list.
>
> There must be at least one blank line before the expandable content.
>
> Provide detailed steps to complete the task here...
>
> Lists can be included inside the icon blocks:
>- Item 1
>- Item 2
>- Item 3
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

- Task 2.

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expandable section with an image.
>
> There must be at least one blank line before the expandable content. 
>
> Provide detailed steps to complete the task here...
>
> Images can be included inside the icon blocks:
>
>!IMAGE[AdvancedLogo.png](AdvancedLogo.png)
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

- Task 3: Perform the task using the values from the following table:

    |Property|Value| 
    |:--|:--| 
    |Property 1|**Value 1**| 
    |Property 2|**Value 2**|
    |Property 3|**Value 3**|
    |Property 4|**Value 4**|

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expandable section with a table.
>
> There must be at least one blank line before the expandable content.
>
> Provide detailed steps to complete the task here...
>
> You can embed a table inside any of the icon blocks:
>
>|Property|Value| 
>|:--|:--| 
>|Property 1|**Value 1**| 
>|Property 2|**Value 2**|
>|Property 3|**Value 3**|
>|Property 4|**Value 4**|
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Click here for more information"). Knowledge items are hidden when hints are off.
:::

- Task 4

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expandable section with a code block.
>
> There must be at least one blank line before the expandable content.
>
> Provide detailed steps to complete the task here...
>
>- Code blocks may be included inside any of the icon block items:
>
>```powershell
>Get-Service
>
>Get-Service | Where Name -like *win* | Out-File .\WinServices.txt
>
>```
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

- Task 5

:::ShowGuided(ShowGuided=Yes)
>[+hint] Expandable section with plain text.
>
> There must be at least one blank line before the expandable content.
>
> Provide detailed steps to complete the task here...
>
:::

:::ShowAdvanced(ShowAdvanced=Yes)
>[!knowledge] Want to learn more? Review the documentation on [creating Task #](https://docs.microsoft.com/ "Create Task # Guidance"). Knowledge items are hidden when hints are off.
:::

===
#Variables 

| Variable | *Value* | Description/Impact |
|:---------|:---------|
| Difficulty    | Guided [or] Advanced [or] Expert [or] Getting Started   |Logo and Alert in Summary section for Expert  |
|cloudEnvironment |None [or] CloudSlice |Shows/hides Cloud slice alert in overview  |
| Global[JobRole]   |**GlobalAdministrator**: *Administrator* <br> **GlobalAnalyst**: *Analyst* <br> **GlobalArchitect**: *Architect*  <br> **GlobalDataScientist**: *Data Scientist* <br> **GlobalDeveloper**: *Developer*  <br> **GlobalDataEngineer**: *Data Engineer* <br> **GlobalDevOpsEngineer**: *DevOps Engineer* <br> **GlobalSecurityEngineer**: *Security Engineer* <br> **GlobalBusinessUser**: *Business User*     | Used in overview description   |
|GlobalCompany |*Hexelo* |Used in overview description |
|GlobalIntroduction | [blank] | Custom text option above Understand scenario in overview | 
|GlobalReqHeader |[blank]|Custom text option below Requirement titles  |
|GlobalReqFooter |[blank]|Custom text option below Check your work |
|GlobalSummary |[blank]|Custom text option below series list in summary  |
|ShowHints |*Yes* [Guided, Advanced, Getting Started]  *No* [Expert]   |Shows/Hides all hints/knowledge blocks  |
|ShowToggle |*Yes* [Advanced, Guided, Getting Started]  *No* [Expert]   |Shows/Hides Hints toggle on Requirement pages  |
|ShowGuided |*Yes* [Guided, Getting Started]  *No* [Advanced, Expert]   |Shows/Hides Guided hints wrapped in ShowGuided |
|ShowAdvanced |*Yes* [Guided, Advanced, Getting Started]  *No* [Expert] |Shows/Hides Advanced content wrapped in ShowAdvanced |
|ShowActivity|*Yes* [Guided, Advanced, Getting Started]  *No* [Expert]  |Shows/Hides Check your work sections wrapped in ShowActivity |
|Debug |*False* |Used in Dev for script testing (Not a required variable, but if there should always be False)  |
|Series|*[LOD# Prefix]* <br>Example: AZ900 |Populates Series list in summary from GitHub  |
|LabMode|*Select Lab Mode*  |Used for lab mode toggle (Not a current feature)|
|ShowLabMode|*Yes* |Used for lab mode toggle (Not a current feature)|

<!-- End of Sample Markdown Elements - Remove this section for production -->

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
<!-- Begin Requirement 4 section -->

# Requirement 4

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

@lab.ActivityGroup(requirement4)
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)

<!-- End Requirement 4 section -->
===
<!-- Begin Requirement 5 section -->

# Requirement 5

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

@lab.ActivityGroup(requirement5)
:::

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)

<!-- End Requirement 5 section -->
===
<!-- Begin Requirement 6 section -->

# Requirement 6

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
:::

@lab.ActivityGroup(requirement6)

!INSTRUCTIONS[](https://raw.githubusercontent.com/LODSContent/Challenge-V3-Framework/main/Templates/Sections/Footer.md)


<!-- End Requirement 6 section -->
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
