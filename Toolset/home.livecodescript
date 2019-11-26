script "home"
constant kImportantTextColor = "#569e54"

on startup
   revSetTestEnvironment($TRAVIS is true)

   -- MW-2011-03-13: Make sure the externals are empty on startup
   set the externals of me to empty
   
   set the allowInterrupts to false
   
   set the cREVLaunching of me to true
   
   revInternal__Log "Start"
   revInternal__Log "Enter", "Startup"
   
   try
      revInternal__SetupLicense
      revInternal__SetupPaths
      revInternal__SetupFolders
      revInternal__SetupStackFiles
      revInternal__SetupSplash
      revInternal__SetupPreferences
      revInternal__SetupCustomizationPath
      revInternal__SetupExternals
   catch tError
      revInternal__Log "Error", tError
   end try
   
   revInternal__Log "Leave", "Startup"
   
   return tError
end startup

on relaunch
   global gREVDevelopment
   if gREVDevelopment then
      pass relaunch
   end if
   
   -- Pass the relaunch request through a hook
   local tParameters
   repeat with x = 1 to the paramCount
      put param(x) into tParameters[x]
   end repeat
   dispatch command "revHookLaunchInstance" to me with tParameters
   if it is "handled" then
      if the result is empty then
         pass relaunch
      else if the result is "background" then
         return "background"
      end if
      return empty
   end if
   
   -- The hook did nothing, so do our default processing
   repeat with x = 1 to the paramcount
      local tStackFile
      put param(x) into tStackFile
      if there is a file tStackFile then -- open it
         revIDEOpenStack tStackFile
      else
         next repeat
      end if
   end repeat
end relaunch

on shutdown
   if "__revInternal_SavePreferences" is in the pendingMessages then
      __revInternal_SavePreferences
   end if
end shutdown

on saveStackRequest
   set the cantModify of me to true
   pass saveStackRequest
end saveStackRequest

on preOpenStack
   local tEdition, tSplashPath
   if the short name of the owner of the target is not "Home" then
      pass preOpenStack
   end if
   
   revInternal__Log "Enter", "Pre-Open Stack"
   
   revInternal__InitialiseDefaults
   
   revInternal__Log "Leave", "Pre-Open Stack"
end preOpenStack

on openStack
   if the short name of the owner of the target is not "Home" then
      pass openStack
   end if
   revInternal__Log "Enter", "Open Stack"
   
   //send "revInternal__openStack" to me in 0 millisecs
   revInternal__openStack
   
   revInternal__Log "Leave", "Open Stack"
end openStack

local sSplashStartTime
on revInternal__openStack
   revInternal__Log "Enter", "revInternal__openStack"
   
   put the milliseconds into sSplashStartTime
   
   set the cREVLaunching of stack "Home" to true
   
   local tSuccess
   put true into tSuccess
   
   try
      if tSuccess then
         revInternal__setSplashStatus "Checking System Parameters..."
         revInternal__InitialiseSystem
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Libraries..."
         revInternal__InitialiseLibraries
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Setting Globals..."
         revInternal__InitialiseGlobals
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Setting Preferences..."
         revInternal__InitialiseOptions
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Standard Icons..."
         set the visible of stack "revGeneralIcons" to false
         put true into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading theme data..."
         revInternal__InitialiseIcons
         put the result into tSuccess	
      end if	
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Patterns..."
         repeat for each item tPatternStack in "revGeneralPatterns,revCompatibilityPatterns1,revCompatibilityPatterns2"
            get there is a stack tPatternStack
         end repeat
         put true into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Script Editor..."
         revInternal__InitialiseScriptEditor
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading User Icon Libraries..."
         revInternal__InitialiseUserLibraries
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Error Management..."
         revInternal__InitialiseErrors
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Menu Bar..."
         revInternal__InitialiseMenus
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Tools..."
         revInternal__InitialiseTools
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Project Browser..."
         revInternal__InitialiseProjectBrowser
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Message Box..."
         revInternal__InitialiseMessageBox
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Plug-ins..."
         revInternal__InitialisePlugIns
         put the result into tSuccess
         set the defaultStack to "home" -- plug ins may take away default stack
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Cleaning Cache"
         revInternal__CleanDocsCache
         put the result into tSuccess
      end if
      
      if tSuccess and not revEnvironmentIsInstalled() then
         revInternal__setSplashStatus "Building Dictionary"
         revInternal__BuildDictionary
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Performing Final Steps..."
         revInternal__setSplashStatus ""
         revInternal__InitialiseFinalSteps
         
         put the result into tSuccess
      end if
   catch tError
      revInternal__Log "Error", tError
   end try
   
   set the cREVLaunching of stack "Home" to false
   
   if not tSuccess then
      quit
   end if
   
   if $REV_TOOLS_PATH is empty and (revInternal__CheckFileAssociations() is true) and (the platform is "win32") then
      if revIDEGetPreference("cDontShowFileAssociationsDialog") is not true then
         modal stack "revFileAssociations"
      end if
   end if
   
   # AL-2015-07-10: Temporarily disable welcome screen
   /*
   if revIDEGetPreference("welcomeScreenShown") is not "true" then
      revIDEOpenPalette "Welcome"
   else if revIDEPrefGet("StartPageShow") is not "false" then
      */
      if revIDEGetPreference("cStartPageShow") is not "false" then
         revIDEOpenPalette "Start Center"
      end if

      -- MM-2011-09-27: The new auto update process is handled entirely by the installer.
      -- Luanch the installer in update mode to begin update process.
      --
      if line 3 of revLicenseInfo is not "evaluation" then
         local tCommand, tOldPath
         put $PATH into tOldPath
         set the itemdelimiter to "/"
         switch the platform
            case "MacOS"
               put item 1 to -5 of the filename me & "/Contents/MacOS/autoupdater" into tCommand
               put quote & tCommand & quote && "install -update" into tCommand
               break
            case "Win32"
               put item 1 to -3 of the filename me & "/.setup.exe" into tCommand
               put quote & tCommand & quote && "install -update" into tCommand
               break
            case "Linux"
               -- MDW-2015-12-19 [[fix_installer]] LC8-style setup filename
               if the processor is "x86_64" then
               		put item 1 to -3 of the filename me & "/setup.x86_64" into tCommand
               else
               		put item 1 to -3 of the filename me & "/setup.x86" into tCommand
               end if
               put tCommand && "install -update" into tCommand
               break
         end switch
         set the itemDel to comma
         open process tCommand for neither
         put tOldPath into $PATH
      end if
      
      close stack "revSplash"
      
      revInternal__Log "Leave", "revInternal__openStack"
      revInternal__Log "End"
      
      -- Now the home stack has loaded, we can allow interrupts..
      set the allowInterrupts to true
end revInternal__openStack

on revInternal__setSplashStatus pMessage
	revInternal__Log "Message", pMessage
   set the statusMessage of stack "revSplash" to pMessage
end revInternal__setSplashStatus


local sLicensePlatform
local sLicenseClass
local sLicenseVersion
local sLicenseName
local sLicenseOrganization
local sLicenseMultiplicity

-- This is the path to the folder containing the IDE's folders
local sToolsPath
-- This is the path to the folder containing user preferences
local sPreferencesPath
-- This is the path to the folder containing user support files
local sCrashLogPath
local sCachePath
-- This is the path to the user-specified IDE customization folder
local sCustomizationPath
-- This is the path to the folder containing per-user dictionary data
local sUserDocsPath


-- This is the path to the folder containing user preferences for the IDE prior to 4.5
local sOldPreferencesPath
-- This is the path to the folder containing support files for the IDE prior to 4.5
local sOldSupportPath

-- MW-2013-06-10: [[ CloneAndRun ]] This is the path containing all the binaries the IDE should
--    use. If empty it means use default installed locations, otherwise this is a git repo build
local sBinariesPath
-- MW-2013-06-10: [[ CloneAndRun ]] This is the path containing the root of the git repository.
local sRepositoryPath

//EJB
local sOverrideRuntimePath, sTestEnvironment

-- Parameterize this so it makes it easier to change.
constant kProductName = "LiveCode"

--------------------------------------------------------------------------------
-- Internal Setup Functions
--

private command revInternal__SetupLicense 
   revInternal__Log "Enter", "License Setup"
   
   put line 1 of the revLicenseInfo into sLicenseName
   put line 2 of the revLicenseInfo into sLicenseOrganization
   put line 3 of the revLicenseInfo into sLicenseClass
   put line 4 of the revLicenseInfo into sLicenseMultiplicity
   
   if sLicenseMultiplicity is empty then
      put 1 into sLicenseMultiplicity
   end if
   
   put the version && "build" && the buildnumber into sLicenseVersion
   
   put revEnvironmentPlatform() into sLicensePlatform
   
   revInternal__Log "Leave", "License Setup"
end revInternal__SetupLicense

private command revInternal__SetupPaths
   revInternal__Log "Enter", "Path Setup"
   
   local tHomePath
   put the filename of me into tHomePath
   
   set the itemDelimiter to "/"
   put item 1 to -3 of tHomePath into sToolsPath
   
   -- MW-2013-06-13: Extract the engine path from 'the address' (needs adjustment
   --    per platform).
   local tEnginePath
   set the itemDelimiter to ":"
   put item 2 to -1 of the address into tEnginePath
   set the itemDelimiter to "/"
   switch revEnvironmentPlatform()
      case "Linux"
         local tOldFolder
         put the folder into tOldFolder
         set the folder to "~"
         put the folder & slash & ".runrev/revolution/enterprise/preferences" into sOldPreferencesPath
         if there is no folder sOldPreferencesPath then
            put the folder & slash & ".runrev/revolution/studio/preferences" into sOldPreferencesPath
         end if
         if there is no folder sOldPreferencesPath then
            put the folder & slash & ".runrev/revolution/media/preferences" into sOldPreferencesPath
         end if
         put the folder & slash & ".runrev/preferences" into sPreferencesPath
         put the folder & slash & ".runrev/cache" into sCachePath
         put the folder & slash & ".runrev/crashlogs" into sCrashLogPath
         put the folder & slash & ".runrev/documentationcache" into sUserDocsPath
         set the folder to tOldFolder
         
         -- MW-2013-06-13: Adjust the engine path for Linux
         put item 1 to -2 of tEnginePath into tEnginePath
         break
      case "MacOS X"
         put specialFolderPath("Preferences") & "/Runtime Revolution/Revolution Enterprise" into sOldPreferencesPath
         if there is no folder sOldPreferencesPath then
            put specialFolderPath("Preferences") & "/Runtime Revolution/Revolution Studio" into sOldPreferencesPath
         end if
         if there is no folder sOldPreferencesPath then
            put specialFolderPath("Preferences") & "/Runtime Revolution/Revolution Media" into sOldPreferencesPath
         end if
         put specialFolderPath("Preferences") & "/RunRev" into sPreferencesPath
         put specialFolderPath("cusr") & "/Library/Application Support/RunRev/Cache" into sCachePath
         put specialFolderPath("cusr") & "/Library/Application Support/RunRev/Crash Logs" into sCrashLogPath
         put specialFolderPath("cusr") & "/Library/Application Support/RunRev/Documentation Cache" into sUserDocsPath
         
         -- MW-2013-06-13: Adjust the engine path for Mac
         put item 1 to -5 of tEnginePath into tEnginePath
         break
      case "Windows"
         -- We put prefereces into the 'Roaming' AppData folder.
         put specialFolderPath(0x001a) & "/Runtime Revolution/Revolution Enterprise/Preferences" into sOldPreferencesPath
         if there is no folder sOldPreferencesPath then
            put specialFolderPath(0x001a) & "/Runtime Revolution/Revolution Studio/Preferences" into sOldPreferencesPath
         end if
         if there is no folder sOldPreferencesPath then
            put specialFolderPath(0x001a) & "/Runtime Revolution/Revolution Media/Preferences" into sOldPreferencesPath
         end if
         put specialFolderPath(0x001a) & "/RunRev/Preferences" into sPreferencesPath
         -- We put everything else in the 'Local' AppData folder.
         put specialFolderPath(0x001c) & "/RunRev/Cache" into sCachePath
         put specialFolderPath(0x001c) & "/RunRev/Crash Logs" into sCrashLogPath
         put specialFolderPath(0x001c) & "/RunRev/Documentation Cache" into sUserDocsPath
         
         -- MW-2013-06-13: Adjust the engine path for Windows
         put item 1 to -2 of tEnginePath into tEnginePath
         break
   end switch
   
   # The docs cache is per-version and edition
   local tEdition
   put tolower(sLicenseClass) into tEdition
   
   local tVersion
   put the version into tVersion
   put replaceText(tVersion, "[-,\.]", "_") into tVersion
   put slash & tVersion & "_" & tEdition after sUserDocsPath
   
   -- MW-2013-06-13: [[ CloneAndRun ]] Set up the binaries path.
   local tRepositoryPath
   put revEnvironmentGuessRepositoryPath(tEnginePath) into tRepositoryPath
   if tRepositoryPath is not empty then
      put tRepositoryPath into sRepositoryPath
      put tEnginePath into sBinariesPath
      
      global gRevDevelopment
      put true into gRevDevelopment
      
      global gRevPopups
      put true into gRevPopups
   else
      put empty into sRepositoryPath
   end if
   
   revInternal__Log "Message", "Tools Path = " & sToolsPath
   revInternal__Log "Message", "Old Preferences Path = " & sOldPreferencesPath
   revInternal__Log "Message", "Preferences Path = " & sPreferencesPath
   revInternal__Log "Message", "Cache Path = " & sCachePath
   revInternal__Log "Message", "Crash Log Path = " & sCrashLogPath
   revInternal__Log "Message", "Binaries Path = " & sBinariesPath
   
   revInternal__Log "Leave", "Path Setup"
end revInternal__SetupPaths

command revInternal__SetupCustomizationPath
  revInternal__Log "Enter", "Customization Path Setup"
  
  # If there is a customization path set in the preferences, and it exists, then use it, otherwise
  # revert to old behavior.
  local tUserCustomizationPath
  put the cCustomizationPath of stack "revPreferences" into tUserCustomizationPath
  if tUserCustomizationPath is not empty then
    put tUserCustomizationPath into sCustomizationPath
  else
    switch revEnvironmentPlatform()
    case "Linux"
      local tOldFolder
      put the folder into tOldFolder
      set the folder to "~"
      put the folder & slash & "my_livecode" into sCustomizationPath
      set the folder to tOldFolder
      break
    case "Windows"
      put specialFolderPath(0x0005) & "/My LiveCode" into sCustomizationPath
      break
    case "MacOS X"
      put specialFolderPath("docs") & "/My LiveCode" into sCustomizationPath
      break
    end switch
    
    revInternal__Log "Message", "Customization Path = " & sCustomizationPath
  end if
  
  revInternal__Log "Leave", "Customization Path Setup"
end revInternal__SetupCustomizationPath

function revInternal__StackFiles
   local tPaletteFolder, tFolders
   put revEnvironmentToolsetPath() & slash & "palettes" into tPaletteFolder
   put tPaletteFolder into tFolders
   
   repeat for each line tFolder in folders(tPaletteFolder)
      if char 1 of tFolder is "." then next repeat
      put return & tPaletteFolder & slash & tFolder after tFolders
   end repeat
   
   put return & revEnvironmentToolsetPath() & slash & "libraries" after tFolders
   if not revEnvironmentIsInstalled() then
      put return & revEnvironmentRepositoryPath() & slash & "ide-support" after tFolders
      
      -- legacy from commercial repo
      put return & revEnvironmentCommercialRepositoryPath() & "/ide/Toolset/libraries" after tFolders
      put revEnvironmentCommercialRepositoryPath() & "/ide/Toolset/palettes" into tPaletteFolder
      repeat for each line tFolder in folders(tPaletteFolder)
         if tFolder begins with "." then next repeat
         put return & tPaletteFolder & slash & tFolder after tFolders
      end repeat
      
      -- components
      local tComponentFolder
      put revEnvironmentCommercialRepositoryPath() & "/components" into tComponentFolder
      repeat for each line tFolder in folders(tComponentFolder)
         if tFolder begins with "." then next repeat
         put return & tComponentFolder & slash & tFolder after tFolders
      end repeat
      
      -- commercial extensions (ensure they are loaded from the repo)
      local tExtensionFolder
      put revEnvironmentCommercialRepositoryPath() & "/extensions/script-libraries" into tExtensionFolder
      repeat for each line tFolder in folders(tExtensionFolder)
         if tFolder begins with "." then next repeat
         put return & tExtensionFolder & slash & tFolder after tFolders
      end repeat
      
      -- extensions (ensure they are loaded from the repo)
      put revEnvironmentRepositoryPath() & "/extensions/script-libraries" into tExtensionFolder
      repeat for each line tFolder in folders(tExtensionFolder)
         if tFolder begins with "." then next repeat
         put return & tExtensionFolder & slash & tFolder after tFolders
      end repeat
   end if	
   
   local tStackFiles, tStackName
   local tStackFilesA, tIDEVersion
   set the itemdel to "."
   
   put item 1 of the version into tIDEVersion
   repeat for each line tPath in tFolders
      repeat for each line tFile in files(tPath)
         if the last item of tFile is not among the items of "rev.livecode.livecodescript" then next repeat
         
         put item 1 to -2 of tFile into tStackName
         
         local tVersion
         put empty into tVersion
         // AL-2015-02-18: [[ Named Stack Versions ]] Check if this stack should be loaded in this version.
         if not (tFile begins with "revidelibrary") and the number of items in tFile > 2 then
            get item -2 of tFile 
            if it is a number then 
               put it into tVersion
               put item 1 to -3 of tFile into tStackName
               if tVersion > tIDEVersion then
                  next repeat
               end if
            end if
         end if
         
         if tStackName is "revpreferences" then next repeat
         
         // AL-2015-02-18: [[ Named Stack Versions ]] Choose a versioned stack file name over an unversioned one, and a later version over an earlier one. 
         local tExistingVersion
         put tStackFilesA[tStackName]["version"] into tExistingVersion
         if tExistingVersion is empty or tVersion > tExistingVersion then
            put tPath & slash & tFile into tStackFilesA[tStackName]["file"]
            put tVersion into tStackFilesA[tStackName]["version"]
         end if	
      end repeat
   end repeat
   
   lock messages
   repeat for each key tKey in tStackFilesA
      try
         put the short name of stack tStackFilesA[tKey]["file"] into tStackName
         delete stack tStackName
         put tStackName & comma & tStackFilesA[tKey]["file"] & return after tStackFiles
      catch e
         revInternal__Log "Error", "Could not load stack:" && tStackFilesA[tKey]["file"]
      end try
   end repeat
   unlock messages
   delete the last char of tStackFiles
   return tStackFiles
end revInternal__StackFiles

private command revInternal__SetupPreferences
   revInternal__Log "Enter", "Preferences Setup"
   
   local tOldPreferencesStackFile, tOldNewPreferencesStackFile
   put sOldPreferencesPath & "/revpreferences.rev" into tOldPreferencesStackFile
   put sPreferencesPath & "/reventerprise.rev" into tOldNewPreferencesStackFile
   
   local tPreferencesStackFile
   put sPreferencesPath & "/" & toLower(kProductName) & ".rev" into tPreferencesStackFile
   
   local tPreferencesStackFile7
   put sPreferencesPath & "/" & toLower(kProductName) & "7.rev" into tPreferencesStackFile7
   
   local tIndex, tStackFiles
   -- First check to see if we have a preferences stack file in the new location that
   -- will not load.
   if there is a file tPreferencesStackFile7 and there is no stack tPreferencesStackFile7 then
      revInternal__Log "Message", "Existing Preferences 7 Stack Corrupted"
      
      put 1 into tIndex
      repeat while there is a file (tPreferencesStackFile7 & ".corrupt." & tIndex)
         add 1 to tIndex
      end repeat
      
      revInternal__Log "Message", "Moving Broken Stack to '" & tPreferencesStackFile7 & "'"
      
      rename file tPreferencesStackFile7 to (tPreferencesStackFile7 & ".corrupt." & tIndex)
   end if
   
   -- Next check to see that if there is a preferences file in the old location, if there
   -- there is no preferences stackfile in the new location.
   if there is no file tPreferencesStackFile7 and there is a file tPreferencesStackFile then
      revInternal__Log "Message", "Found 2.7 preferences file, copying to new location."
      put url ("binfile:" & tPreferencesStackFile) into url ("binfile:" & tPreferencesStackFile7)
   end if
   
   if there is no file tPreferencesStackFile7 and there is a file tOldNewPreferencesStackFile then
      revInternal__Log "Message", "Found preferences in new location with old name, copying to new location."
      -- MM-2012-05-03: Fixed typo - changed tOldPreferencesStackFile to tOldNewPreferencesStackFile
      put url ("binfile:" & tOldNewPreferencesStackFile) into url ("binfile:" & tPreferencesStackFile7)
   end if
   
   -- Next check to see if there is a preferences file in the new location under the
   -- name 'reventerprise'.
   if there is no file tPreferencesStackFile7 and there is a file tOldNewPreferencesStackFile then
      revInternal__Log "Message", "Found preferences in new location with old name, copying to new location."
      -- MM-2012-05-03: Fixed typo - changed tOldPreferencesStackFile to tOldNewPreferencesStackFile
      put url ("binfile:" & tOldNewPreferencesStackFile) into url ("binfile:" & tPreferencesStackFile7)
   end if
   
   if there is no file tPreferencesStackFile7 then
      revInternal__Log "Message", "No Existing Preferences Stack Found"
      revInternal__Log "Message", "Copying template preferences to '" & tPreferencesStackFile7 & "'"
      
      lock messages
      if there is not a stack "revpreferences" then
         create invisible stack "revpreferences"
      end if
      set the filename of stack "revpreferences" to tPreferencesStackFile7
      revInternal__ResetPreferences
      unlock messages
      
   end if
   
   -- ensure the script of stack preferences is empty
   -- as setprops could be dangerous
   set the script of stack tPreferencesStackFile7 to empty
   
   put the stackFiles of stack "Home" into tStackFiles
   put return & "revPreferences", tPreferencesStackFile7 after tStackFiles
   set the stackFiles of stack "Home" to tStackFiles
   
   revInternal__Log "Message", "Mapping Stack 'revpreferences.rev' to stackfile '" & tPreferencesStackFile7 & "'"
   
   revInternal__Log "Leave", "Preferences Setup"
end revInternal__SetupPreferences

private command revInternal__SetupFolders
   revInternal__Log "Enter", "Folders Setup"
   
   local tPath, tComponent
   set the itemDelimiter to "/"
   
   revInternal__Log "Message", "Setting up Preferences Path"
   revInternal__EnsureFolder sPreferencesPath
   
   revInternal__Log "Message", "Setting up Cache Path"
   revInternal__EnsureFolder sCachePath
   
   revInternal__Log "Message", "Setting up Crash Log Path"
   revInternal__EnsureFolder sCrashLogPath
   
   revInternal__Log "Message", "Setting up Docs Path"
   revInternal__EnsureFolder sUserDocsPath
   
   revInternal__Log "Leave", "Folders Setup"
end revInternal__SetupFolders

private command revInternal__SetupSplash
	palette stack "revSplash"
end revInternal__SetupSplash

command revInternal__ResetPreferences
   -- clear the preferences stack
   set the customKeys of stack "revPreferences" to empty
   set the customPropertySets of stack "revPreferences" to empty
   
   local tPropsArray
   -- default custom property set
   put "true" into tPropsArray["cREVToolsPaintToolsVisible"]
   put "false" into tPropsArray["cDestroyStack"]
   put "false" into tPropsArray["cRevPopups"]
   put "417,113" into tPropsArray["cREVMsgTabRectGlobalProperties"]
   put "155" into tPropsArray["cREVPlayerWidth"]
   put "23" into tPropsArray["cButtonHeight"]
   put "true" into tPropsArray["cShowProfileEditor"]
   put "200" into tPropsArray["cScrollbarwidth"]
   put "false" into tPropsArray["cREVMsgShowUIMessages"]
   put "false" into tPropsArray["cSEHidePalettes"]
   put "120" into tPropsArray["cREVImageWidth"]
   put "500" into tPropsArray["tooltip delay"]
   put "417,72" into tPropsArray["cREVMsgTabRectSingle Line"]
   put "false" into tPropsArray["cREVMsgShowUIBackScripts"]
   put "539,432" into tPropsArray["cREVGeoTopLeft"]
   put "70378" into tPropsArray["cREVDBCode"]
   put "276" into tPropsArray["cREVScriptHeight"]
   put "2" into tPropsArray["cGridSize"]
   put "483,214,1015,476" into tPropsArray["cVariableWatcherRect"]
   put "false" into tPropsArray["cShowrevProps"]
   put "Pixels" into tPropsArray["cREVRulerMeasurement"]
   put "100" into tPropsArray["cMacOSScrollbarWidth"]
   put "1,2,3,4,5,7" into tPropsArray["cControlTabs"]
   put "500" into tPropsArray["cREVToolTipDelay"]
   put "250" into tPropsArray["cTabButtonwidth"]
   put "true" into tPropsArray["cGoAlign"]
   put "0" into tPropsArray["cREVRotatePrev2"]
   put "993,712" into tPropsArray["cREVPropertyPaletteTopLeft"]
   put "true" into tPropsArray["cLiveColor"]
   put "modification date" into tPropsArray["cRecentSort"]
   put "true" into tPropsArray["cDocsFirstRun"]
   put "86400" into tPropsArray["cUpdate,MaxAutoPopupFrequency"]
   put "true" into tPropsArray["cREVExtension"]
   put "102" into tPropsArray["cMenuWidth"]
   put "417,72" into tPropsArray["cREVMsgTabRectcard id 1147"]
   put "468,131" into tPropsArray["cAppearanceTopLeft"]
   put "false" into tPropsArray["cREVDefaultMenubar"]
   put "417,113" into tPropsArray["cREVMsgTabRectbackScripts"]
   put "true" into tPropsArray["cGrid"]
   put "30" into tPropsArray["cNumRecent"]
   put "false" into tPropsArray["cShowAsHandlers"]
   put "false" into tPropsArray["revDocsAlreadySeen"]
   put "120" into tPropsArray["cREVImageHeight"]
   put "82" into tPropsArray["cButtonWidth"]
   put "true" into tPropsArray["cREVProfileReadOnlyWarning"]
   put "6,7,9" into tPropsArray["cCardTabs"]
   put "16" into tPropsArray["cMacOSScrollbarHeight"]
   put "true" into tPropsArray["cFirstRun"]
   put "14" into tPropsArray["cMacOSProgressScrollbarHeight"]
   put "mouseMove" into tPropsArray["suppressedMessages"]
   put "true" into tPropsArray["cAutoFormat"]
   put "true" into tPropsArray["cREVScriptShortcut"]
   put "false" into tPropsArray["cShowRevolutionStacks"]
   put "22" into tPropsArray["cMenuHeight"]
   put "1067,251,1882,827" into tPropsArray["cRevDocsRect"]
   put "Gray88" into tPropsArray["cBackDropColor"]
   put "Gray88" into tPropsArray["cBackdrop"]
   put "false" into tPropsArray["cREVMsgShowUIFrontScripts"]
   put "false" into tPropsArray["revstack"]
   put "100" into tPropsArray["cMacOSProgressScrollbarWidth"]
   put "false" into tPropsArray["cREVUIScriptShortcut"]
   put "60,27" into tPropsArray["cREVMenuBarTopLeft"]
   put "322" into tPropsArray["cREVFieldFirstTabHeight"]
   put "500" into tPropsArray["cTraceDelay"]
   put "0" into tPropsArray["cREVRotatePrev1"]
   put "250" into tPropsArray["cFieldWidth"]
   put "16" into tPropsArray["cScrollbarHeight"]
   put "true" into tPropsArray["cToolbarIcons"]
   put "true" into tPropsArray["cShowAudioclipsclips"]
   put "1,2,3,4,5" into tPropsArray["cAudioclipTabs"]
   put "620,235" into tPropsArray["cREVMsgTabRectSingleLine"]
   put "Sections List" into tPropsArray["revHelpDefaultSection"]
   put "false" into tPropsArray["cCaseSensitive"]
   put "auto" into tPropsArray["cLargeFonts"]
   put "Yellow" into tPropsArray["yellow"]
   put "417,113" into tPropsArray["cREVMsgTabRectGlobalVariables"]
   put "417,113" into tPropsArray["cREVMsgTabRectpendingMessages"]
   put "Property Inspector" into tPropsArray["cABCommandDoubleClick"]
   put "1" into tPropsArray["cREVTipNumber"]
   put "417,113" into tPropsArray["cREVMsgTabRectstacksInUse"]
   put format("blue\nbrown\ndarkorange\nred") into tPropsArray["cBuiltInColors"]
   put "don't remove" into tPropsArray["cASKDestroy"]
   put "Gray50" into tPropsArray["cSelectionHandle"]
   put "128,103" into tPropsArray["cREVMaximizedScriptEditorTopLeft"]
   put "true" into tPropsArray["suppressIDE"]
   put "Property Inspector" into tPropsArray["cABOptionDoubleClick"]
   put "45" into tPropsArray["cREVRotatePrev5"]
   put "170,131" into tPropsArray["cPaletteTopLeft"]
   put "false" into tPropsArray["cNOPICTWarning"]
   put "470,460" into tPropsArray["cREVMsgTopLeft"]
   put format("cButtonWidth,100\ncButtonHeight,20\ncTabButtonwidth,250\ncTabButtonHeight,160\ncMenuWidth,130\ncMenuHeight,20\ncFieldWidth,250\ncFieldHeight,160\ncLabelFieldWidth,100\ncLabelFieldHeight,20\ncMacOSScrollbarHeight,16\ncMacOSProgressScrollbarHeight,14\ncScrollbarWidth,200\ncScrollbarHeight,20\ncREVGraphicWidth,120\ncREVGraphicHeight,120\ncREVImageWidth,120\ncREVImageHeight,120\ncREVPlayerWidth,320\ncREVPlayerHeight,256") into tPropsArray["New Field 2"]
   put "120" into tPropsArray["cREVGraphicHeight"]
   put "Dictionary" into tPropsArray["cRevDocsCurrentCard"]
   put "385" into tPropsArray["cREVScriptWidth"]
   put "487" into tPropsArray["cREVUnmaximizedScriptWidth"]
   put "false" into tPropsArray["cREVDontMaximizeScriptEditor"]
   put "true" into tPropsArray["cDontWrap"]
   put "false" into tPropsArray["cVariableChecking"]
   put "302" into tPropsArray["cAppBrowserWidgetLeft"]
   put "true" into tPropsArray["cUngroupWarning"]
   put "false" into tPropsArray["resizeable"]
   put "false" into tPropsArray["cNavigationArrows"]
   put "457,430,853,680" into tPropsArray["cMessageWatcherRect"]
   put "287,261" into tPropsArray["cREVMsgTabRectrevbasic"]
   put "true" into tPropsArray["cSort"]
   put "false" into tPropsArray["cREVMsgAutoRefresh"]
   put "true" into tPropsArray["cVariablePreservation"]
   put "100" into tPropsArray["cLabelFieldWidth"]
   put "false" into tPropsArray["cREVMsgShowUIVariables"]
   put "false" into tPropsArray["cHandlerList"]
   put "red" into tPropsArray["red"]
   put "selectedObject" into tPropsArray["cREVMsgIntelligenceObject"]
   put "false" into tPropsArray["cSEHideErrors"]
   put "56" into tPropsArray["cFieldHeight"]
   put "300" into tPropsArray["cREVUnmaximizedScriptHeight"]
   put "13,125" into tPropsArray["cToolsTopLeft"]
   put "--" into tPropsArray["cCommentCharacter"]
   put "97,92,657,440" into tPropsArray["cScriptEditorRect"]
   put "11" into tPropsArray["cREVRotatePrev4"]
   put "530,564" into tPropsArray["cREVMsgTabRectrevscript"]
   put "146,123,800,408" into tPropsArray["cAppBrowserRect"]
   put "true" into tPropsArray["cREVAutoCreateProfilesWarning"]
   put "false" into tPropsArray["cREVSaveStacksAfterMoving"]
   put "false" into tPropsArray["cREVAutoCreateProfiles"]
   put "417,113" into tPropsArray["cREVMsgTabRectGlobal Variables"]
   put "118" into tPropsArray["cREVPlayerHeight"]
   put "true" into tPropsArray["cShowVideoclips"]
   put "false" into tPropsArray["cWholeMatches"]
   put "false" into tPropsArray["cVerboseDebug"]
   put "417,99" into tPropsArray["cREVMsgTabRectMultipleLines"]
   put "true" into tPropsArray["cBreakPoints"]
   put "false" into tPropsArray["cREVGeoOpen"]
   put "462,120" into tPropsArray["cREVAOTopLeft"]
   put "blackgreen" into tPropsArray["cCustomColorsList"]
   put "Penguin" into tPropsArray["revHelpUnixReligion"]
   put format("cButtonWidth,82\ncButtonHeight,23\ncTabButtonwidth,250\ncTabButtonHeight,160\ncMenuWidth,102\ncMenuHeight,22\ncFieldWidth,250\ncFieldHeight,56\ncLabelFieldWidth,100\ncLabelFieldHeight,21\ncMacOSScrollbarHeight,16\ncMacOSProgressScrollbarHeight,14\ncScrollbarWidth,200\ncScrollbarHeight,16\ncREVGraphicWidth,120\ncREVGraphicHeight,120\ncREVImageWidth,120\ncREVImageHeight,120\ncREVPlayerWidth,155\ncREVPlayerHeight,118") into tPropsArray["cDefaultSizes"]
   put "false" into tPropsArray["cSelectGrouped"]
   put "false" into tPropsArray["cSEHideMessageBox"]
   put "1,2,3,4,5" into tPropsArray["cVideoclipTabs"]
   put "true" into tPropsArray["cREVMacOSMenubar"]
   put "false" into tPropsArray["cREVProfileReadOnly"]
   put "Yellow" into tPropsArray["revHelpHiliteColor"]
   put "true" into tPropsArray["cToolbarText"]
   put "true" into tPropsArray["cREVScriptDebugMode"]
   put "21" into tPropsArray["cLabelFieldHeight"]
   put "120" into tPropsArray["cREVGraphicWidth"]
   put "417,99" into tPropsArray["cREVMsgTabRectMultiple Lines"]
   put "30" into tPropsArray["Num Recent Files"]
   put "568,259" into tPropsArray["cREVProfileEditorTopLeft"]
   put "417,113" into tPropsArray["cREVMsgTabRectfrontScripts"]
   put "11" into tPropsArray["cREVRotatePrev3"]
   put "338" into tPropsArray["cREVButtonSecondTabHeight"]
   put "true" into tPropsArray["cREVHelpText"]
   put "160" into tPropsArray["cTabButtonHeight"]
   put "287,261" into tPropsArray["cREVMsgTabRectrevstack"]
   put "417,113" into tPropsArray["cREVMsgTabRectGlobal Properties"]
   put "true" into tPropsArray["cShowAudioclipclips"]
   put "revolutionli" into tPropsArray["cREVDBName"]
   put "true" into tPropsArray["cDocsQuickLinksVisible"]
   put "true" into tPropsArray["cStartPageShow"]
   put "278" into tPropsArray["cREVErrorsPaletteExpandedHeight"]
   put "true" into tPropsArray["cShowAudioclips"]
   put "filtering" into tPropsArray["revHelpListMethod"]
   set the customProperties[""] of stack "revPreferences" to tPropsArray
   delete variable tPropsArray
   
   -- cABDoubleClick
   put "Play" into tPropsArray["videoclips"]
   put "Toplevel" into tPropsArray["stacks"]
   put "Property Inspector" into tPropsArray["controls"]
   put "Play" into tPropsArray["audioclips"]
   put "Go" into tPropsArray["cards"]
   set the customProperties["cABDoubleClick"] of stack "revPreferences" to tPropsArray
   delete variable tPropsArray
   
   -- cABCommandDoubleClick
   put "Edit Script" into tPropsArray["videoclips"]
   put "Edit Script" into tPropsArray["stacks"]
   put "Edit Script" into tPropsArray["controls"]
   put "Edit Script" into tPropsArray["audioclips"]
   put "Edit Script" into tPropsArray["cards"]
   set the customProperties["cABCommandDoubleClick"] of stack "revPreferences" to tPropsArray
   delete variable tPropsArray
   
   -- cABOptionDoubleClick
   put "Property Inspector" into tPropsArray["videoclips"]
   put "Property Inspector" into tPropsArray["stacks"]
   put "Property Inspector" into tPropsArray["controls"]
   put "Property Inspector" into tPropsArray["audioclips"]
   put "Property Inspector" into tPropsArray["cards"]
   set the customProperties["cABOptionDoubleClick"] of stack "revPreferences" to tPropsArray
   delete variable tPropsArray
   
   revInternal__SavePreferences
end revInternal__ResetPreferences

--------------------------------------------------------------------------------
-- Internal Utility Functions
--
--
local sSavePreferencesMessage

command revInternal__SavePreferences
   cancel sSavePreferencesMessage
   send "__revInternal_SavePreferences" to me in 30 seconds
   put the result into sSavePreferencesMessage
end revInternal__SavePreferences

command __revInternal_SavePreferences
   lock messages
   -- MM-2014-02-22: [[ Bug 11442 ]] Saving the prefs stack when security permissions is true is not possible.
   try
      save stack "revPreferences" with format "7.0"
   catch tError
   end try
   unlock messages
end __revInternal_SavePreferences

private command revInternal__EnsureFolder pFolder
  revInternal__Log "Enter", "Ensuring Folder '" & pFolder & "'"
  
  local tPath
  local tComponent
  
  set the itemDelimiter to "/"
  put item 1 of pFolder & "/" into tPath
  repeat for each item tComponent in item 2 to -1 of pFolder
    put tComponent & "/" after tPath
    if there is no folder (char 1 to -2 of tPath) then
      create folder char 1 to -2 of tPath
      if the result is empty then
        revInternal__Log "Message", "Creation of folder '" & char 1 to -2 of tPath & "' succeeded"
      else
        revInternal__Log "Message", "Creation of folder '" & char 1 to -2 of tPath & "' failed"
      end if
    end if
  end repeat
  
  revInternal__Log "Leave", "Ensuring Folder '" & pFolder & "'"
end revInternal__EnsureFolder

function revInternal__CheckFileAssociations 
   local tEnginePath
   set the itemDelimiter to ":"
   put item 2 to -1 of the address into tEnginePath
   
   if the platform is "win32" then
      -- If .rev, .livecode or .livecodescript classes are not present, then we need new assocs
      # AL-2015-03-13: [[ Bug 14910 ]] Add .livecodescript to valid stack file extensions on windows 
      if queryRegistry("HKEY_CURRENT_USER\Software\Classes\.rev\") is not "RevolutionStack" or \
            queryRegistry("HKEY_CURRENT_USER\Software\Classes\.livecode\") is not "LiveCodeStack" or \ 
            queryRegistry("HKEY_CURRENT_USER\Software\Classes\.livecodescript\") is not "LiveCodeScriptOnlyStack"
      then 
         return true 
      end if 
      
      -- If .rev, .livecode or .livecodescript classes are not present, then we need new assocs
      # AL-2015-03-13: [[ Bug 14910 ]] Add .livecodescript to valid stack file extensions on windows 
      replace slash with backslash in tEnginePath
      get queryRegistry("HKEY_CURRENT_USER\Software\Classes\RevolutionStack\Shell\Open\Command\") 
      if word 1 of it is not quote & tEnginePath & quote then 
         return true 
      end if 
      get queryRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeStack\Shell\Open\Command\") 
      if word 1 of it is not quote & tEnginePath & quote then 
         return true 
      end if 
      get queryRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeScriptOnlyStack\Shell\Open\Command\") 
      if word 1 of it is not quote & tEnginePath & quote then 
         return true 
      end if 
   else
      -- Do Linux at some point!
   end if
   
   return false 
end revInternal__CheckFileAssociations

command revInternal__InstallFileAssociations 
   local tEnginePath
   set the itemDelimiter to ":"
   put item 2 to -1 of the address into tEnginePath
   
   if the platform is "win32" then
      replace slash with backslash in tEnginePath
      # AL-2015-03-13: [[ Bug 14910 ]] Add .livecodescript to valid stack file extensions on windows 
      get setRegistry("HKEY_CURRENT_USER\Software\Classes\.rev\", "RevolutionStack") and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\RevolutionStack\Shell\Open\Command\", quote & tEnginePath & quote && quote & "%1" & quote) and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\RevolutionStack\DefaultIcon\", tEnginePath & comma & "1") and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\.livecode\", "LiveCodeStack") and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeStack\Shell\Open\Command\", quote & tEnginePath & quote && quote & "%1" & quote) and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeStack\DefaultIcon\", tEnginePath & comma & "1") and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\.livecodescript\", "LiveCodeScriptOnlyStack") and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeScriptOnlyStack\Shell\Open\Command\", quote & tEnginePath & quote && quote & "%1" & quote) and \
            setRegistry("HKEY_CURRENT_USER\Software\Classes\LiveCodeScriptOnlyStack\DefaultIcon\", tEnginePath & comma & "1")
      if it is false then
         answer error "Failed to set file associations."
      else
         _internal call "notify_association_changed"
      end if
   else
   end if
end revInternal__InstallFileAssociations

local sLogIndent, sLogPath, sLog
private command revInternal__LogToFile pType, pMessage   
   if sLogPath is empty then
      exit revInternal__LogToFile
   end if
   
   open file sLogPath for text append
   
   if pType is not "Message" then
      put pType && pMessage into pMessage
   end if
   
   repeat for each line tLine in pMessage
      if sLogIndent > 0 then
         write char 1 to sLogIndent of "                                " to file sLogPath
      end if
      write tLine & return to file sLogPath
   end repeat
   
   close file sLogPath
end revInternal__LogToFile

private command revInternal__LogToVariable pType, pMessage  
   if pType is "Error" then 
	   repeat for each line tLine in pMessage
    	  put tLine & return after sLog["Error"]
	   end repeat
   end if
   
   if pType is not "Message" then
      put pType && pMessage into pMessage
   end if
   
   repeat for each line tLine in pMessage
      if sLogIndent > 0 then
         put char 1 to sLogIndent of "                                " after sLog["Message"]
      end if
      put tLine & return after sLog["Message"]
   end repeat
   
end revInternal__LogToVariable

-- For test mode
function revEnvironmentGetStartupLog pType
   if sTestEnvironment is not true then
      return empty
   end if
   
   return sLog[pType]
end revEnvironmentGetStartupLog

command revInternal__Log pType, pMessage
   if pType is "Start" then
      local tLogPath
      put 0 into sLogIndent
      switch revEnvironmentPlatform()
         case "Linux"
            put "~/.runrev/logs/" & toLower(kProductName) & "_tools_log.txt" into tLogPath
            break
         case "MacOS X"
            put specialFolderPath("cusr") & "/Library/Logs/RunRev/" & kProductName & "ToolsLog.txt"  into tLogPath
            break
         case "Windows"
            -- Make sure we put logs in the 'Local' AppData section.
            put specialFolderPath(0x001c) & "/RunRev/Logs/" & kProductName & "ToolsLog.txt" into tLogPath
            break
      end switch
      set the itemDelimiter to "/"
      revInternal__EnsureFolder item 1 to -2 of tLogPath
      if there is no folder item 1 to -2 of tLogPath then
         put empty into tLogPath
      end if
      set the itemDelimiter to comma
      if tLogPath is not empty then
         put tLogPath into sLogPath
         revInternal__Log "Message", "-------- Startup Started:" && the internet date
      end if
      exit revInternal__Log
   else if pType is "End" then
      revInternal__Log "Message", "-------- Startup Ended:" && the internet date
      put empty into sLogPath
      exit revInternal__Log
   end if
   
   if pType is "Leave" then
      subtract 2 from sLogIndent
   else if pType is "Enter" then
      add 2 to sLogIndent
   end if
   
   if sTestEnvironment is true then
      revInternal__LogToVariable pType, pMessage
   else
      revInternal__LogToFile pType, pMessage
   end if
end revInternal__Log

--------------------------------------------------------------------------------
-- Internal Initialisation Functions
--

command revInternal__InitialiseSystem
   local tSuccess
   
   revInternal__Log "Enter", "System Initialisation"
   
   put true into tSuccess
   
   get the cCrashReportStyle of stack "revPreferences"
   if it is empty then
      get "Small"
   end if
   if sLicensePlatform is "Windows" and it is not "None" then
      local tCrashSettings, tVersion
      put the version into tVersion
      replace "." with "_" in tVersion
      replace "-" with "_" in tVersion
      
      put it is "Medium" into tCrashSettings["verbose"]
      
      convert the seconds to dateItems
      put format("%s/%s-%s-%04d_%02d_%02d-%02d_%02d_%02d.dmp", \
             sCrashLogPath, kProductName, tVersion, item 1 of it, item 2 of it, item 3 of it, \
             item 4 of it, item 5 of it, item 6 of it) into tCrashSettings["filename"]
      
      revInternal__Log "Message", "Configuring crash log output to" && tCrashSettings["filename"]
      do "set the revCrashReportSettings to tCrashSettings"
   end if

   revInternal__Log "Leave", "System Initialisation"
   
   return tSuccess
end revInternal__InitialiseSystem

command revInternal__InitialiseGlobals
   revInternal__Log "Enter", "Globals Initialisation"
   
   global gREVDevelopment
   if gREVDevelopment is empty then
      put false into gREVDevelopment
   end if
   
   global gREVAccelerator
   if the platform is "MacOS" then
      put "Cmd" into gREVAccelerator
   else
      put "Cntrl+" into gREVAccelerator
   end if
   
   revInternal__SetAppIcon 210096
   revInternal__SetSmallAppIcon 210096
   
   revInternal__Log "Leave", "Globals Initialisation"
   
   return true
end revInternal__InitialiseGlobals

private function revInternal__FilterHandlerList pList
   local tNewList
   repeat for each line tLine in pList
      if tLine begins with "P" then
         next repeat
      end if
      put word 2 of tLine & return after tNewList
   end repeat
   delete the last char of tNewList
   return tNewList
end revInternal__FilterHandlerList

command revInternal__InitialiseLibraries
   revInternal__Log "Enter", "Libraries Initialisation"
   	    	 	
   try 	 	
      insert script of stack "revInitialisationLibrary" into back 	 
   catch tError 	 	
      revInternal__Log "Error", "Error loading initialisation library" & return & tError 	 	
   end try
   
   revInternal_SetJAVA_HOME
   
   local tLoadList
   put "revCommonLibrary" into tLoadList 
   put return & "revDatabaseLibrary" after tLoadList 
   put return & "revIDEDocumentationLibrary" after tLoadList
   put return & "revMetadataLibrary" after tLoadList   
   put return & "revSBLibrary" after tLoadList
   put return & "revIDELibrary" after tLoadList
   put return & "revidemessagehandlerlibrary" after tLoadList
   put return & "revBackScriptLibrary" after tLoadList 
   put return & "revDeployLibrary" after tLoadList
   put return & "revDebuggerLibrary" after tLoadList 
   put return & "revLibUrl" after tLoadList 
   put return & "revPrintLibrary" after tLoadList 
   put return & "revAnimationLibrary" after tLoadList 
   put return & "revGeometryLibrary" after tLoadList 
   put return & "revXMLRPCLibrary" after tLoadList 
   put return & "revProfilesLibrary" after tLoadList 
   put return & "revTableLibrary" after tLoadList 
   put return & "revhtml5urllibrary" after tLoadList

   if revEnvironmentEditionProperty("autocomplete_pro") then
      put return & "autocomplete-pro" after tLoadList
   end if
   
   if revEnvironmentEditionProperty("autocomplete") then
      put return & "autocomplete" after tLoadList
   end if
   
   local tBackList
   put "revidedeveloperextensionlibrary" into tBackList
   put return & "revsaveasstandalone" after tBackList
   put return & "revsaveasiosstandalone" after tBackList
   put return & "revsaveasandroidstandalone" after tBackList
   put return & "revsaveasemscriptenstandalone" after tBackList
   put return & "revOnlineLibrary" after tBackList
   put return & "revCore" after tBackList
   
   # AL-2015-09-02: [[ Bug 15841 ]] Temporarily add project browser library to prevent preference errors
   put return & "revIDEProjectBrowserLibrary" after tBackList
   
   local tLib
   repeat for each line tLib in tLoadList	 
      revInternal__Log "Message", "Loading library" && tLib	
      revInternal__LoadLibrary tLib
	  if the result is not empty then
	     revInternal__Log "Error", the result 
	  end if
   end repeat
   
   try	
      repeat for each line tLib in tBackList
         insert script of stack tLib into back 	 
      end repeat
   catch tError 	 	
      revInternal__Log "Error", "Error loading library" && tLib & return & tError 	 	
   end try
   
   # MW-2010-10-13: [[ Bug 8600 ]] Make sure the handler lists of the rev frontscript, backscript and shortcuts script
   #    are all up to date (used by revNoMessages script).
   set the cREVGeneral["handlerlist"] of stack "revBackScriptLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revBackScriptLibrary")
   
   # Now we have the IDE scripts in place, initiaize the deployment platforms
   try
      revIDEDeployInitialize
   end try
   
   -- Load libraries in the Ext externals bundle
   if there is a folder revEnvironmentExtPath() then
      local tOldFolder
      put the folder into tOldFolder
      
      set the folder to revEnvironmentExtPath()
      repeat for each line tExternal in the folders
         if tExternal is empty or tExternal is "." or tExternal is ".." then
            next repeat
         end if
         set the folder to revEnvironmentExtPath() & "/" & tExternal
         
         local tFiles
         put the files into tFiles
         filter tFiles with "*.livecode*"
         
         repeat for each line tFile in tFiles
            if there is a stack tFile then
               revInternal__LoadIfLibrary the short name of stack tFile
            end if
         end repeat
      end repeat
      
      set the folder to tOldFolder
   end if
   
   revInternal__Log "Leave", "Libraries Initialisation"
   
   return true
end revInternal__InitialiseLibraries

private command revInternal__SetupExternals
   revInternal__Log "Enter", "Externals Setup"
   
   local tExtension
   switch revEnvironmentPlatform()
      case "Linux"
         put "so" into tExtension
         break
      case "MacOS X"
         put "bundle" into tExtension
         break
      case "Windows"
         put "dll" into tExtension
         break
   end switch
   
   local tOldFolder, tExternals
   put the folder into tOldFolder
   
   -- MW-2013-06-13: [[ CloneAndRun ]] If this is an installed build, load all externals in the
   --    (installed) Externals folder. Otherwise, use the binaries path.
   if revEnvironmentIsInstalled() then
      set the folder to revEnvironmentExternalsPath()
   else
      set the folder to revEnvironmentBinariesPath()
   end if
   repeat for each line tExternal in the folders & return & the files
      if tExternal is empty or tExternal is "." or tExternal is ".." then
         next repeat
      end if
      put the folder & "/" & tExternal & return after tExternals
   end repeat
   
   -- Load the Ext externals bundle
   if there is a folder revEnvironmentExtPath() then
      set the folder to revEnvironmentExtPath()
      repeat for each line tExternal in the folders
         if tExternal is empty or tExternal is "." or tExternal is ".." then
            next repeat
         end if
         set the folder to revEnvironmentExtPath() & "/" & tExternal
         
         -- The folder contains externals for multiple platforms, potentially
         -- Remember: .bundle "files" are really folders
         local tFiles
         put the files & return & the folders into tFiles
         filter tFiles with ("*." & tExtension)
         
         repeat for each line tFile in tFiles
            put revEnvironmentExtPath() & "/" & tExternal & "/" & tFile & return after tExternals
         end repeat
      end repeat
   end if
   
   if there is a folder revEnvironmentUserExternalsPath() then
      set the folder to revEnvironmentUserExternalsPath()
      repeat for each line tExternal in the folders & return & the files
         if tExternal is empty or tExternal is "." or tExternal is ".." then
            next repeat
         end if
         put revEnvironmentUserExternalsPath() & "/" & tExternal & return after tExternals
      end repeat
   end if
   
   set the folder to tOldFolder
   
   filter tExternals with ("*." & tExtension)
   
   # OK-2007-09-24 : Support for legacy drivers. If the legacy drivers are in use, then the revdb
   # external should come from the user legacy externals folder rather than the main externals folder.
   if the cREVUseLegacyDrivers of stack "revPreferences" then
      local tOffset
      put lineOffset("/revdb.", tExternals) into tOffset
      if tOffset is not 0 then
         put revEnvironmentUserExternalsPath() & "/Legacy/revdb." & tExtension into line tOffset of tExternals
      end if
   end if
   
   set the externals of stack "Home" to tExternals
   
   repeat for each line tExternal in the externals of stack "Home"
      revInternal__Log "Message", "Registering External '" & tExternal & "'"
   end repeat
   
   revInternal__Log "Leave", "Externals Setup"
end revInternal__SetupExternals

private command revInternal__SetupStackFiles
   revInternal__Log "Enter", "Stack Files Setup"
   
   set the stackFiles of stack "Home" to revInternal__StackFiles()
   
   local tStackFile
   set the itemDelimiter to comma
   repeat for each line tStackFile in the stackFiles of stack "Home"
      revInternal__Log "Message", "Mapping Stack '" & item 1 of tStackFile & "' to stackfile '" & item 2 of tStackFile & "'"
   end repeat
   
   revInternal__Log "Leave", "Stack Files Setup"
end revInternal__SetupStackFiles

command revInternal__InitialiseDefaults
   revInternal__Log "Enter", "Defaults Initialisation"
      
   set the _ideoverride of stack "home" to true

   switch sLicensePlatform
      case "MacOS X"
         set the stackFileType to "RevoRSTK"
         set the hidePalettes to true
         set the dontUseNS to false
         set the itemdelimiter to "."
         revInternal__Log "message", "Trying to set the default text of stack home"

         hide stack "revMacCursors"    
         break
      case "Windows"
         set the hidePalettes to false
         set the shellCommand to "cmd.exe"
         hide stack "revCursors"
         break
      case "Linux"
         set the hidePalettes to false
         
         hide stack "revLinuxCursors"
         hide stack "revCursors"
         break
      default
         set the hidePalettes to false
         
         hide stack "revLinuxCursors"
         hide stack "revCursors"
         break
   end switch
   
   set the traceDelay to the cTraceDelay of stack "revPreferences"
   
   revInternal__Log "Leave", "Defaults Initialisation"
   
   return true
end revInternal__InitialiseDefaults

command revInternal__InitialiseOptions
   revInternal__Log "Enter", "Options Initialisation"
   
   set the selectGroupedControls to the cSelectGrouped of stack "revPreferences"
   set the tooltipDelay to the cREVToolTipDelay of stack "revPreferences"
   set the grid to the cGrid of stack "revPreferences"
   set the scriptTextFont to the cREVScriptFont of stack "revPreferences"
   set the scriptTextSize to the cREVScriptSize of stack "revPreferences"
   
   if the cHttpProxy of stack "revPreferences" is not empty then
      set the httpProxy to the cHttpProxy of stack "revPreferences"
   end if
   
   set the gridSize to the cGridSize of stack "revPreferences"
   
   if the cSelectionHandleColor of stack "revPreferences" is empty then
      set the selectionHandleColor to "Gray50"
   else
      set the selectionHandleColor to the cSelectionHandleColor of stack "revPreferences"
   end if
   
   set the navigationArrows to the cNavigationArrows of stack "revPreferences"
   
   global gREVShowStacks, gREVDevelopment
   if gREVDevelopment then
      put true into gREVShowStacks
   else if the cShowRevolutionStacks of stack "revPreferences" is empty then
      put false into gREVShowStacks
   else
      put the cShowRevolutionStacks of stack "revPreferences" into gREVShowStacks
   end if
   
   global gREVLanguageNames
   put the cLanguageNames of card 1 of stack "revPreferences" into gREVLanguageNames
   
   revInternal__Log "Message", "Obtained preference languageNames = " & gREVLanguageNames
   
   global gREVPopups
   put the cRevPopups of stack "revPreferences" into gREVPopups
   
   global gREVAutoFormat
   put the cAutoFormat of stack "revPreferences" into gREVAutoFormat
   
   global gREVUIScriptShortcut
   put the cREVUIScriptShortcut of stack "revPreferences" into gREVUIScriptShortcut
   
   global gREVScriptShortcut
   put the cREVScriptShortcut of stack "revPreferences" into gREVScriptShortcut
   
   global gREVCommentCharacter
   if the cCommentCharacter of stack "revPreferences" is not empty then
      put the cCommentCharacter of stack "revPreferences" into gREVCommentCharacter
   else
      put "--" into gREVCommentCharacter
   end if
   
   global gREVTemplateMasterName
   put the cREVTemplateMasterName of stack "revPreferences" into gREVTemplateMasterName
   
   global gREVAutoCreateProfiles
   put the cREVAutoCreateProfiles of stack "revPreferences" into gREVAutoCreateProfiles
   
   global gREVProfileReadOnly
   put the cREVProfileReadOnly of stack "revPreferences" into gREVProfileReadOnly
   
   revInternal__Log "Leave", "Options Initialisation"
   
   return true
end revInternal__InitialiseOptions

command revInternal__InitialiseUserLibraries
  local tEnvironmentIcons, tUserIcons, tList
  
  revInternal__Log "Enter", "User Libraries Initialisation"
  put revAbsoluteFolderListing(revEnvironmentResourcesPath("Icon Libraries")) into tEnvironmentIcons
  put revAbsoluteFolderListing(revEnvironmentUserResourcesPath("Icon Libraries")) into tUserIcons
  put revCombineFilePaths(tUserIcons,tEnvironmentIcons) into tList
  
  lock messages
  
  repeat for each line l in tList 
    if there is a stack l then
      hide stack l
    end if
  end repeat
  
  unlock messages
  
  revInternal__Log "Leave", "User Libraries Initialisation"
  
  return true
end revInternal__InitialiseUserLibraries

command revInternal__InitialiseScriptEditor
   revInternal__Log "Enter", "Script Editor Initialisation"
   
   set the behavior of stack revScriptEditorMain() to the long id of stack revIDEScriptEditorBehavior("utilities")

   # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
   set the showInvisibles of stack revScriptEditorMain() to false
   set the _ideoverride of stack revScriptEditorMain() to true
   
   revInternal__Log "Leave", "Script Editor Initialisation"
   
   return true
end revInternal__InitialiseScriptEditor

command revInternal__InitialiseErrors
  revInternal__Log "Enter", "Errors Initialisation"
  
  # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
  set the showInvisibles of stack "revErrorDisplay" to false
  set the _ideoverride of stack "revErrorDisplay" to true
   
  revInternal__Log "Leave", "Errors Initialisation"
  
  return true
end revInternal__InitialiseErrors

command revInternal__InitialiseTools
   revInternal__Log "Enter", "Tools Initialisation"
   
   local tToolsStackName
   put revIDEPaletteToStackName("Tools") into tToolsStackName
   
   --PM-2015-10-05: [[ Bug 16099 ]] IDE should default to Pointer tool and highlight its icon on the Tools palette
   revIDESetTool "pointer"
   
   lock screen
   go invisible stack tToolsStackName as palette
   revIDEPositionPalette("tools")
   
   # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
   set the showInvisibles of stack tToolsStackName to false
   set the _ideoverride of stack tToolsStackName to true
   
   show stack tToolsStackName
   unlock screen 
   
   revInternal__Log "Leave", "Tools Initialisation"
   
   return true
end revInternal__InitialiseTools

command revInternal__InitialiseIcons
   revInternal__Log "Enter", "Icons Initialisation"
   
   lock screen
   hide stack "revicons"
   
   # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
   set the showInvisibles of stack "revicons" to false
   set the _ideoverride of stack "revicons" to true
   
   unlock screen
   
   revInternal__Log "Leave", "Icons Initialisation"
   
   return true
end revInternal__InitialiseIcons

command revInternal__InitialiseMenus
   revInternal__Log "Enter", "Menus Initialisation"
   
   revInternal__Log "message", "Trying to get the platform"
   revInternal__Log "message", the platform
   
   local tMenuBar
   put revIDEPaletteToStackName("menubar") into tMenuBar
   
   if the platform is "MacOS" then
      lock messages
      modeless stack tMenuBar
      unlock messages
   else
      toplevel stack tMenuBar
   end if
   set the defaultMenuBar to the long id of group "revMenuBar" of stack tMenuBar
   
   revInternal__ConstrainStack tMenuBar
   
   local tToolsRight
   put the right of stack revIDEPaletteToStackName("tools") into tToolsRight
   
   local tWindowRect
   put line (the screen of stack tMenuBar) of the working screenRects into tWindowRect
   if tWindowRect is not empty then
	   if tToolsRight < 100 then put tToolsRight + 5 into item 1 of tWindowRect
	   put the bottom of stack tMenuBar + 5 into item 2 of tWindowRect
	   set the windowBoundingRect to tWindowRect
   end if
   
   # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
   set the showInvisibles of stack tMenuBar to false
   set the _ideoverride of stack tMenubar to true
   
   revInternal__Log "Leave", "Menus Initialisation"
   
   if the platform is not "macos" or revIDEGetPreference("cToolbarText") or revIDEGetPreference("cToolbarIcons") then
      show stack tMenuBar
   end if
   
   return true
end revInternal__InitialiseMenus

command revInternal__InitialiseProjectBrowser
   revInternal__Log "Enter", "Project Browser Initialisation"

   if the cAppOverview of stack "revPreferences" and there is a stack "revApplicationOverview" then
      set the _ideoverride of stack "revApplicationOverview" to true
      toplevel "revApplicationOverview"
   end if

   // EJB
   if there is a stack "revProjectBrowser" then
      if the cIDEProjectBrowserOpen of stack "revPreferences" is not false then
         modeless "revProjectBrowser"
      end if
   end if
   
   revInternal__Log "Leave", "Project Browser Initialisation"
   
   return true
end revInternal__InitialiseProjectBrowser

command revInternal__InitialiseMessageBox
   revInternal__Log "Enter", "Message Box Initialisation"
   
   if the platform is among the items of "MacOS,Win32" then
      set the style of stack "Message Box" to "palette"
   else
      set the style of stack "Message Box" to "modeless"
   end if
   dispatch "ideInitialiseMessageBox" to stack "Message Box"
   
   revInternal__Log "Leave", "Message Box Initialisation"
   
   return true
end revInternal__InitialiseMessageBox

command revInternal__InitialisePlugIns
   revInternal__Log "Enter", "Plug-Ins Initialisation"
   
   revIDEUpdatePlugins
   
   local tPluginInfo
   put revIDEPlugins() into tPluginInfo
   repeat for each key tPlugin in revIDEPlugins()
      if tPluginInfo[tPlugin]["startup"] is true then
         revIDEOpenPlugin tPlugin
      end if
   end repeat
   
   revInternal__Log "Leave", "Plug-Ins Initialisation"
   
   return true
end revInternal__InitialisePlugIns

command revInternal__InitialiseFinalSteps
   revInternal__Log "Enter", "Final Initialisation"
   
   --the following *MUST* be the last item to avoid excess sending to overview as environment loads
   revInternal__Log "Message", "Installing Remaining Libraries"

   revInternal__LoadLibrary "revFrontScriptLibrary"
   if the result is not empty then
      revInternal__Log "Error", the result  
   end if
      
   set the cREVGeneral["handlerlist"] of stack "revFrontScriptLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revFrontScriptLibrary")
   
   revInternal__LoadLibrary "revShortCutsLibrary"
   if the result is not empty then
      revInternal__Log "Error", the result  
   end if
   
   set the cREVGeneral["handlerlist"] of stack "revShortCutsLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revShortCutsLibrary")
   
   revInternal__Log "Message", "Setting up verbose debugging"
   send "revVerboseDebug" && the cVerboseDebug of stack "revPreferences" to stack "revFrontScriptLibrary"
   
   if the cBackDrop of stack "revPreferences" is not "none" then
      revInternal__Log "Message", "Setting up backdrop"
      set the backdrop to the cBackDropColor of stack "revPreferences"
   end if
   
   revInternal__Log "Message", "Closing Splash"
   if the milliseconds - sSplashStartTime < 500 then
      wait 500 - (the milliseconds - sSplashStartTime) milliseconds
   end if
   close stack "home"
   
   revInternal__Log "Message", "Resetting Cursors"
   reset cursors
   
   if the cStartupRevOnline of stack "revPreferences" then
      revInternal__Log "Message", "Launching revOnline"
      send "revGoOnline" to stack "revOnline"
   end if
   
   revInternal__Log "Message", "Initialising revFrontScript"
   
   revInternal__Log "Leave", "Final Initialisation"
   
   return true
end revInternal__InitialiseFinalSteps

command revInternal__BuildDictionary
   revInternal__Log "Enter", "Building Dictionary"
   revIDEGenerateDistributedDocs
   revInternal__Log "Leave", "Building Dictionary"
   return true
end revInternal__BuildDictionary

command revInternal__CleanDocsCache
   revInternal__Log "Enter", "Cleaning Docs Cache"
   # Clean up old non-versioned docs
   local tOldDocsFolder
   switch revEnvironmentPlatform()
      case "Linux"
         put "~/.runrev/docs" into tOldDocsFolder
         break
      case "MacOS X"
         put specialFolderPath("cusr") & "/Library/Application Support/RunRev/Docs" into tOldDocsFolder
         break
      case "Windows"
         put specialFolderPath(0x001c) & "/RunRev/Docs" into tOldDocsFolder
         break
   end switch
   if there is a folder tOldDocsFolder then
      revDeleteFolder tOldDocsFolder
   end if
   revInternal__Log "Leave", "Cleaning Docs Cache"
   return true
end revInternal__CleanDocsCache

command revInternal__ConstrainStack pStack
  local tStackTitleBarRect
  local tTitleBarHeight, tBorderWidth, tTitleBarBuffer
  local tScreenNo, tWorkingScreenRect
  if the decorations of stack pStack is empty then
    put 0 into tTitleBarHeight
    put 0 into tBorderWidth
  else
    -- We assume this is about 30 pixels
    put 30 into tTitleBarHeight
    if the platform is "macos" then
      put 0 into tBorderWidth
    else
      put 5 into tBorderWidth
    end if
  end if
  
  put 30 into tTitleBarBuffer
   
  put the rect of stack pStack into tStackTitleBarRect
  subtract tTitleBarHeight from item 2 of tStackTitleBarRect -- the "real" stack rect
  put item 2 of tStackTitleBarRect + tTitleBarHeight into item 4 of tStackTitleBarRect
   
  -- We calculate the intersection with its current screen..
  put the screen of stack pStack into tScreenNo
  put line tScreenNo of the working screenRects into tWorkingScreenRect
   
  -- Simply check top, bottom, left and right
  #top
  if item 4 of tStackTitleBarRect < item 2 of tWorkingScreenRect + tTitleBarHeight then
    -- move the stack down, into view
    set the top of stack pStack to item 2 of tWorkingScreenRect + tTitleBarHeight
  end if
  #bottom
  if item 2 of tStackTitleBarRect > item 4 of tWorkingScreenRect then
    set the bottom of stack pStack to item 4 of tWorkingScreenRect
  end if
  #left
  if item 3 of tStackTitleBarRect < item 1 of tWorkingScreenRect + tTitleBarBuffer then -- allow a tiny "buffer"
    set the left of stack pStack to item 1 of tWorkingScreenRect + tBorderWidth -- allowing for a window border
  end if
  #right
  if item 1 of tStackTitleBarRect > item 3 of tWorkingScreenRect - tTitleBarBuffer then
    set the right of stack pStack to item 3 of tWorkingScreenRect - tBorderWidth -- allowing for a window border
  end if
   
end revInternal__ConstrainStack

--------------------------------------------------------------------------------
-- Global Environment Functions - Installation Structure
--
-- <Installation>/
--   Third Party/
--     TechSmiths EnSharpen Codec/
--   Supporting Materials/
--     Made With Logos/
--     Sample Icons/
--   Installation Data/
--   <Distribution>/
--     Documentation/
--       xml/
--       pdf/
--       html/
--       rev/
--     Externals/
--     Plugins/
--     Resources/
--       Icon Libraries/
--       Object Libraries/
--       Sample Projects/
--       Tutorials/
--       Examples/
--     Runtime/
--       <platform>/
--         <architecture>/
--         <externals>/
--         <support>/
--     Toolset/
--     Unsupported/
--

function revEnvironmentToolsPath
   return sToolsPath
end revEnvironmentToolsPath

function revEnvironmentResourcesPath pType
  local tFolder
  
  put hookToolsPath("resources", sToolsPath & "/Resources") into tFolder
  
  if pType is not empty then
    put slash & pType after tFolder
  end if
  
  return tFolder
end revEnvironmentResourcesPath

function revEnvironmentDocumentationPath
  return hookToolsPath("documentation", sToolsPath & "/Documentation")
end revEnvironmentDocumentationPath

function revEnvironmentToolsetPath
  return hookToolsPath("toolset", sToolsPath & "/Toolset")
end revEnvironmentToolsetPath

function revEnvironmentEditionProperty pProp, pEdition
   if pEdition is empty then
      put the editionType into pEdition
   end if
   
   if pProp is "skin" then
      return revEnvironmentToolsetPath() & "/resources/" & pEdition & "/ideSkin"
   end if
   
   switch pEdition
      case "community"
         switch pProp
            case "name"
               return "Community"
            case "color"
               return 173,208,54
            case "pb_line_selected_color"
               return 226,238,185
            case "revonline_hilite_color"
               return 156,199,45
            case "revabout_hilite_color"
               return 106,139,15
            case "revsplash_text_color"
               return 0,0,0
            case "start_center_tile_color_step"
               return -9
            case "password_protection"
               return false
            case "open_source_required"
               return true
            case "splash_strap"
               return empty
            case "upgrade_mini_url"
               return "https://livecode.com/products/community-plus-ide-2/"
            case "upgrade_url"
               return "https://livecode.com/products/community-plus-ide/"  
            case "upgrade_edition"
               return "communityplus"
            case "edition_external_url"
               return "https://livecode.com/products/community-edition/"
            case "autocomplete"
            case "autocomplete_pro"
               return false
            case "script_profiler"
               return false
         end switch
         break
      case "communityplus"
         switch pProp
            case "name"
               return "Community Plus"
            case "color"
               return 49,163,102
            case "pb_line_selected_color"
               return 226,238,185
            case "revonline_hilite_color"
               return 49,163,102
            case "revabout_hilite_color"
               return 49,163,102
            case "revsplash_text_color"
               return 0,0,0
            case "start_center_tile_color_step"
               return -9
            case "password_protection"
               return false
            case "open_source_required"
               return true
            case "splash_strap"
               return empty
            case "upgrade_mini_url"
               return empty
            case "upgrade_url"
               return empty
            case "upgrade_edition"
               return "commercial"
            case "edition_external_url"
               return "https://livecode.com/products/community-plus-edition/"
            case "autocomplete"
               return true
            case "autocomplete_pro"
               return false
            case "script_profiler"
               return false
         end switch
         break
      case "indy"
      case "commercial"
         switch pProp
            case "name"
               return "Indy"
            case "color"
               return 28,154,206
            case "pb_line_selected_color"
               return 222,243,255
            case "revonline_hilite_color"
               return 124,193,222
            case "revabout_hilite_color"
               return 44,113,170
            case "revsplash_text_color"
               return 0,0,0
            case "start_center_tile_color_step"
               return 0
            case "password_protection"
               return true
            case "open_source_required"
               return false
            case "splash_strap"
               if revLicenseInfo["com.livecode.norevenuelimit"] is not empty then
                  return empty
               else
                  return "<p>This Indy license is only valid for organizations with annual revenues of $500,000 USD or less</p>"
               end if
            case "upgrade_mini_url"
               return empty
            case "upgrade_url"
               return empty
            case "upgrade_edition"
               return "professional"
            case "edition_external_url"
               return "https://livecode.com/products/indy-edition/"
            case "autocomplete"
            case "autocomplete_pro"
               return true
            case "script_profiler"
               return false
         end switch
         break
      case "business"
      case "professional"
         switch pProp
            case "name"
               return "Business"
            case "color"
               return 82,82,82
            case "pb_line_selected_color"
               return 222,243,255
            case "revonline_hilite_color"
               return 124,193,222
            case "revabout_hilite_color"
               return 44,113,170
            case "revsplash_text_color"
               return 255,255,255
            case "start_center_tile_color_step"
               return 0
            case "password_protection"
               return true
            case "open_source_required"
               return false
            case "splash_strap"
               return empty
            case "upgrade_mini_url"
               return empty
            case "upgrade_url"
               return empty
            case "upgrade_edition"
               return empty
            case "edition_external_url"
               return "https://livecode.com/products/business-edition/"
            case "autocomplete"
            case "autocomplete_pro"
               return true
            case "script_profiler"
               return true
         end switch
         break
   end switch
   
   throw "Unknown edition property"
end revEnvironmentEditionProperty

function revEnvironmentPluginsPath
   return hookToolsPath("plugins", sToolsPath & "/Plugins")
end revEnvironmentPluginsPath

function revEnvironmentDevelopmentPluginsPath
   if not revEnvironmentIsInstalled() then
      -- check for private repo plugins
      set the itemDelimiter to slash
      local tPath
      put item 1 to -3 of sToolsPath & "/ide/Plugins" into tPath
      if there is a folder tPath then
         return tPath
      end if
   end if
   return empty
end revEnvironmentDevelopmentPluginsPath

function revEnvironmentExternalsPath
  return hookToolsPath("externals", sToolsPath & "/Externals")
end revEnvironmentExternalsPath

function revEnvironmentExtensionsPath
   return line 1 of revEnvironmentExtensionsPaths()
end revEnvironmentExtensionsPath

function revEnvironmentExtensionsPaths
   if revEnvironmentIsInstalled() then
      return hookToolsPath("extensions", sToolsPath & "/Extensions")
   else
      return sBinariesPath & slash & "packaged_extensions"
   end if
end revEnvironmentExtensionsPaths

function revEnvironmentRuntimePath
  return hookToolsPath("runtime", sToolsPath & "/Runtime")
end revEnvironmentRuntimePath

function revEnvironmentUserRuntimePath
  return sCustomizationPath & "/Runtime"
end revEnvironmentUserRuntimePath

function revEnvironmentExtPath
   return hookToolsPath("ext", sToolsPath & "/Ext")
end revEnvironmentExtPath

//EJB for Testing System
function revOverrideRuntimePath
  return sOverrideRuntimePath
end revOverrideRuntimePath

command revSetOverrideRuntimePath pPath
   put pPath into sOverrideRuntimePath
end revSetOverrideRuntimePath

command revSetTestEnvironment pValue
   put pValue into sTestEnvironment
end revSetTestEnvironment

function revTestEnvironment
   return sTestEnvironment
end revTestEnvironment

//

function revEnvironmentCustomizationPath
  return sCustomizationPath
end revEnvironmentCustomizationPath

function revEnvironmentUserResourcesPath pType, pCreate
  local tFolder
  
  put sCustomizationPath & "/Resources" into tFolder
  if pType is not empty then
    put "/" & pType after tFolder
  end if
  
  if pCreate then
    revInternal__EnsureFolder tFolder
  end if
  
  if there is no folder tFolder then
    return empty
  end if
  
  return tFolder
end revEnvironmentUserResourcesPath

function revEnvironmentUserToolsetPath
  return sCustomizationPath & "/Toolset"
end revEnvironmentUserToolsetPath

function revEnvironmentUserPluginsPath
  return sCustomizationPath & "/Plugins"
end revEnvironmentUserPluginsPath

function revEnvironmentUserExternalsPath
  return sCustomizationPath & "/Externals"
end revEnvironmentUserExternalsPath

function revEnvironmentUserExtensionsPath
  return sCustomizationPath & "/Extensions"
end revEnvironmentUserExtensionsPath

function revEnvironmentUserPreferencesPath
  return sPreferencesPath
end revEnvironmentUserPreferencesPath

function revEnvironmentUserCachePath
  return sCachePath
end revEnvironmentUserCachePath

function revEnvironmentUserDocsPath
  return sUserDocsPath
end revEnvironmentUserDocsPath

function revEnvironmentIsUpdateable
  return true
end revEnvironmentIsUpdateable

function revEnvironmentIsMultiVersion
  return false
end revEnvironmentIsMultiVersion

function revEnvironmentIsPortable
  return false
end revEnvironmentIsPortable

-- MW-2013-06-13: [[ CloneAndRun ]] Returns true if this is an installed IDE (as opposed
--   to being run from a repo build).
function revEnvironmentIsInstalled
   return sBinariesPath is empty
end revEnvironmentIsInstalled

-- MW-2013-06-13: [[ CloneAndRun ]] Returns the path to the binaries for a repo build.
function revEnvironmentBinariesPath
   return sBinariesPath
end revEnvironmentBinariesPath

// SN-2015-05-15: [[ DeployAllPlatforms ]] Allow the deployment to happen for any
//  platform, from any repository platform
function revEnvironmentNonNativeBinariesPath pPlatform, pSDK
   local tNonNativeBinariesPath
   put sRepositoryPath into tNonNativeBinariesPath
   
   switch pPlatform
      case "Windows"
         put slash & "win-x86-bin" after tNonNativeBinariesPath
         break
      case "Windows x86-64"
      case "Windows x64"
      case "Windows x86_64"
         put slash & "win-x86_64-bin" after tNonNativeBinariesPath
         break
      case "Linux"
         put slash & "linux-x86-bin" after tNonNativeBinariesPath
         break
      case "Linux x86-64"
      case "Linux x64"
      case "Linux x86_64"
         put slash & "linux-x86_64-bin" after tNonNativeBinariesPath
         break
      case "Linux armv6_hf"
         put slash & "linux-armv6_hf-bin" after tNonNativeBinariesPath
         break
      case "MacOS"
      case "MacOSX x86-32"
      case "MacOSX x86_32"
      case "MacOSX x86-64"
      case "MacOSX x64"
      case "MacOSX x86_64"
         put slash & "mac-bin" after tNonNativeBinariesPath
         break
      case "Android"
      case "Android armv6"
         put slash & "android-armv6-bin" after tNonNativeBinariesPath
         break
      case "Android armv7"
         put slash & "android-armv7-bin" after tNonNativeBinariesPath
         break
      case "Android arm64"
         put slash & "android-arm64-bin" after tNonNativeBinariesPath
         break
      case "Android x86"
         put slash & "android-x86-bin" after tNonNativeBinariesPath
         break
      case "Android x86_64"
         put slash & "android-x86_64-bin" after tNonNativeBinariesPath
         break
      case "Emscripten"
      case "HTML5"
         put slash & "emscripten-bin" after tNonNativeBinariesPath
         break
      case "iOS"
         put slash & "ios-bin" & slash & pSDK after tNonNativeBinariesPath
         break
      default 
         return empty
   end switch
   
   return tNonNativeBinariesPath
end revEnvironmentNonNativeBinariesPath

-- MW-2013-06-13: [[ CloneAndRun ]] Returns the path to the repo.
function revEnvironmentRepositoryPath
   return sRepositoryPath
end revEnvironmentRepositoryPath

function revEnvironmentCommercialRepositoryPath
   set the itemDelimiter to slash
   return item 1 to -2 of sRepositoryPath
end revEnvironmentCommercialRepositoryPath

-- Deprecated Path Functions

function revEnvironmentPreferencePath
   return revEnvironmentUserPreferencesPath()
end revEnvironmentPreferencePath

function revEnvironmentPreferencesPath
   return revEnvironmentUserPreferencesPath()
end revEnvironmentPreferencesPath

function revEnvironmentCachePath
   throw "Component has attempted to use a non-existant environment path function: revEnvironmentCachePath"
end revEnvironmentCachePath

function revEnvironmentSupportPath
   throw "Component has attempted to use a non-existant environment path function: revEnvironmentSupportPath"
end revEnvironmentSupportPath 

function revEnvironmentInstallationPath
   throw "Component has attempted to use a non-existant environment path function: revEnvironmentInstallationPath"
end revEnvironmentInstallationPath

function revEnvironmentDistributionPath
   throw "Component has attempted to use a non-existant environment path function: revEnvironmentDistributionPath"
end revEnvironmentDistributionPath

private function hookToolsPath pPath, pDefault
   dispatch function "revHookGetToolsPath" to me with pPath
   if it is "handled" then
      return the result
   end if
   return pDefault
end hookToolsPath


-- Works out the source repository path for the engine (if any)
private function revEnvironmentGuessRepositoryPath pEnginePath
   -- Build and package directories
   local tPlatform
   local tProcessor
   local tBuildDir
   local tPackageDir
   local tAltPackageDir
   local tRepositoryPath
   
   switch the platform
      case "win32"
         put "win" into tPlatform
         break
      case "macos"
         put "mac" into tPlatform
         break
      default
         put the platform into tPlatform
         break
   end switch
   
   switch the processor
      case "i386"
         put "x86" into tProcessor
         break
      default
         put the processor into tProcessor
         break
   end switch
   
   put "build-" & tPlatform & "-" & tProcessor into tBuildDir
   put tPlatform & "-" & tProcessor & "-bin" into tPackageDir
   put tPlatform & "-bin" into tAltPackageDir
   
   set the itemDelimiter to "/"
   if tBuildDir is among the items of pEnginePath then
      put item 1 to (itemOffset(tBuildDir,pEnginePath) - 1) of pEnginePath into tRepositoryPath
   else if tPackageDir is among the items of pEnginePath then
      put item 1 to (itemOffset(tPackageDir,pEnginePath) - 1) of pEnginePath into tRepositoryPath
   else if tAltPackageDir is among the items of pEnginePath then
      put item 1 to (itemOffset(tAltPackageDir,pEnginePath) -1) of pEnginePath into tRepositoryPath
   else if "_build" is among the items of pEnginePath then
      put item 1 to (itemOffset("_build",pEnginePath) - 1) of pEnginePath into tRepositoryPath
   end if
   
   return tRepositoryPath
end revEnvironmentGuessRepositoryPath

--------------------------------------------------------------------------------
-- Global Environment Functions - General Support
--

function revEnvironmentPlatform
   local tPlatform
   
   switch the platform
      case "Linux"
         put "Linux" into tPlatform
         break
      case "MacOS"
         put "MacOS X" into tPlatform
         break
      case "Win32"
         put "Windows" into tPlatform
         break
      default
         put "Unsupported" into tPlatform
         break
   end switch
   
   return tPlatform
end revEnvironmentPlatform
