# Data Science Challenge Lab Windows 10 Setup.

This setup is built on our standard Gold Copy Windows 10 VM with Chocolatey and Visual Studio Code installed. It also has R and R studio installed.

HANS - if you want to add in the bit you do please do.

## Clone this repository to d:\temp

```PowerShell
md d:\temp
clone https://github.com/LODSContent/ChallengeLabs_BuildAssets d:\temp
```

## Run Visual Studio Code in Administrator mode
I recommend using Visual Studio Code to manage the scripts

- From the Start menu, run Visual Studio Code in Administrator mode
- Open the d:\temp folder
- The scripts for this installation are under the **Data-Science** folder

## Install the R Studio extensions

- From the Start menu, open R Studio
- Create a new R script file
- In R Studio, run parts 1, 2, and 3 of the R-Sudio-Setup.rs file seperately.
  - Copy part 1 into the script file and then select all of the text and select the run button on the toolbar
  - Repeat for steps 2 and 3
  - On step 3, you will need to assent to the prompt. You will only be prompted once.
- The R Studio extensions will take several minutes to install. You can continue with other installations while this runs. Ignore error messages. 
- Once the script has finished, clean up R studio:
  - In the console (bottom), press Ctrl-L to clear it.
  - On the right side of the window, clear the current objects and history

## Install additional software and sample data

- In Visual Studio Code, open the Build-Services.ps1 file.
- Select each line (not comments), right-click and select **Run selection**.
  - Each line may take up to several minutes to install.

## Clean up

- Once both the R studio install and the software install are complete, delete the d:\temp folder and run a standard image cleanup. 