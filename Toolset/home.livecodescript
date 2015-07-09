script "home"
constant kImportantTextColor = "#569e54"

on startup
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
end startup

on relaunch
   global gREVDevelopment
   if gREVDevelopment then
      pass relaunch
   end if
   
   -- Pass the relaunch request through a hook
   local tParameters
   repeat with x = 1 to the paramCount()
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
   repeat with x = 1 to the paramcount()
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
         revInternal__setSplashStatus "Loading Application Overview..."
         revInternal__InitialiseApplicationOverview
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Message Box..."
         revInternal__InitialiseMessageBox
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Debugger..."
         revInternal__InitialiseDebugger
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading QuickTime..."
         revInternal__InitialiseQuickTime
         put the result into tSuccess
      end if
      
      if tSuccess then
         revInternal__setSplashStatus "Loading Plug-ins..."
         revInternal__InitialisePlugIns
         put the result into tSuccess
         set the defaultStack to "home" -- plug ins may take away default stack
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
      if revIDEPrefGet("DontShowFileAssociationsDialog") is not true then
         modal stack "revFileAssociations"
      end if
   end if
   
   if revIDEGetPreference("welcomeScreenShown") is not "true" then
      revIDEOpenPalette "Welcome"
   else if revIDEPrefGet("StartPageShow") is not "false" then
      revIDEOpenPalette "Start Center"
   end if
   
   try 	 	
      revIDEOpenPropertyInspectorControllerStacks 	 	
   end try 
   
   -- MM-2011-09-27: The new auto update process is handled entirely by the installer.
   -- Luanch the installer in update mode to begin update process.
   --
   if line 3 of revLicenseInfo is not "evaluation" then
      local tCommand, tOldPath
      put $PATH into tOldPath
      set the itemdelimiter to "/"
      switch the platform
         case "MacOS"
            put item 1 to -5 of the filename me & "/LiveCode Setup.app/Contents/MacOS/installer" into tCommand
            put quote & tCommand & quote && "install -update" into tCommand
            break
         case "Win32"
            put item 1 to -3 of the filename me & "/.setup.exe" into tCommand
            put quote & tCommand & quote && "install -update" into tCommand
            break
         case "Linux"
            --put item 1 to -3 of the filename me into $PATH
            --put ".setup.x86 install -update" into tCommand
            put item 1 to -3 of the filename me & "/.setup.x86" into tCommand
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
         
         -- MW-2013-06-13: Adjust the engine path for Windows
         put item 1 to -2 of tEnginePath into tEnginePath
         break
   end switch
   
   -- MW-2013-06-13: [[ CloneAndRun ]] Set up the binaries path.
   local tRepositoryPath
   put revEnvironmentGuessRepositoryPath(tEnginePath) into tRepositoryPath
   if tRepositoryPath is not empty then
      put tRepositoryPath into sRepositoryPath
      put tEnginePath into sBinariesPath
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
	
	set the defaultfolder to tPaletteFolder
	repeat for each line tFolder in the folders
		if char 1 of tFolder is "." then next repeat
		put return & tPaletteFolder & slash & tFolder after tFolders
	end repeat
	
	put return & revEnvironmentToolsetPath() & slash & "libraries" after tFolders
	if revEnvironmentIsInstalled() then
		put return & revEnvironmentToolsetPath() after tFolders
	else
		put return & revEnvironmentRepositoryPath() & slash & "ide-support" after tFolders
	end if	

	
	local tStackFiles, tStackName
	local tStackFilesA, tIDEVersion
	set the itemdel to "."
	
	put item 1 of the version into tIDEVersion
	repeat for each line tPath in tFolders
		set the defaultfolder to tPath
		
		repeat for each line tFile in the files
			if the last item of tFile is not among the items of "rev.livecode.livecodescript" then next repeat
			
			put item 1 to -2 of tFile into tStackName
			
			local tVersion
			put empty into tVersion
			// AL-2015-02-18: [[ Named Stack Versions ]] Check if this stack should be loaded in this version.
			if the number of items in tFile > 2 then
				get item -2 of tFile 
				if it is a number then 
					put it into tVersion
					put item 1 to -3 of tFile into tStackName
					if tVersion > tIDEVersion then
						next repeat
					end if
				end if
			end if
			
			if tStackName is "revpagesetupdialog" then put "Page Setup Dialog" into tStackName
			else if tStackName is "revprintdialog" then put "Print Dialog" into tStackName
			else if tStackName is "revcolorchooser" then put "Color Chooser" into tStackName
			else if tStackName is "revfileselector" then put "File Selector" into tStackName
			else if tStackName is "revanswerdialog" then put "Answer Dialog" into tStackName
			else if tStackName is "revaskdialog" then put "Ask Dialog" into tStackName
			else if tStackName is "revmessagebox" then put "Message Box" into tStackName
			else if tStackName is "revideprojectbrowserview" then put "revIDEProjectBrowser" into tStackName
			else if tStackName is "revscripteditor" then put "revNewScriptEditor" into tStackName
        	# AL-2015-03-12: [[ Bug ]] Make sure Linux stacks included in standalones have the correct name
        	else if tStackName is "revprinterchooser" then put "Printer Chooser" into tStackName
         	else if tStackName is "revpagesetup" then put "Page Setup" into tStackName
         			
			
			// AL-2015-02-18: [[ Named Stack Versions ]] Choose a versioned stack file name over an unversioned one, and a later version over an earlier one. 
			local tExistingVersion
			put tStackFilesA[tStackName]["version"] into tExistingVersion
			if tExistingVersion is empty or tVersion > tExistingVersion then
				put tPath & slash & tFile into tStackFilesA[tStackName]["file"]
				put tVersion into tStackFilesA[tStackName]["version"]
			end if	
		end repeat
	end repeat
	
	repeat for each key tKey in tStackFilesA
		put tKey & comma & tStackFilesA[tKey]["file"] & return after tStackFiles
	end repeat
	delete the last char of tStackFiles
	return tStackFiles
   /*
   local tStackFiles
   local tUserPath, tPath
   put revEnvironmentToolsPath() into tPath
   put revEnvironmentUserToolsetPath() into tUserPath
   
   local tItem
   set the itemDelimiter to tab
   repeat for each line tItem in field "Toolset" of card "Data" of stack "Home"
      if item 2 of tItem is "Resources" then
         put item 1 of tItem, tPath & slash & item 3 of tItem & return after tStackFiles
      else if item 2 of tItem is "Unsupported" then
         put item 1 of tItem, tPath & "/Unsupported/" & item 3 of tItem & return after tStackFiles
      else if there is a file (tUserPath & "/" & item 3 of tItem) then
         put item 1 of tItem, tUserPath & "/" & item 3 of tItem & return after tStackFiles
      else if not revEnvironmentIsInstalled() and (item 3 of tItem ends with ".livecodescript") then
         put item 1 of tItem, (revEnvironmentRepositoryPath() & slash & "ide-support" & slash & item 3 of tItem) & return after tStackfiles
      else
         put item 1 of tItem, tPath & "/Toolset/" & item 3 of tItem & return after tStackFiles
      end if
   end repeat
   return tStackFiles
   */
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
   if the buildnumber < 10000 then
      -- First check to see if we have a preferences stack file in the new location that
      -- will not load.
      if there is a file tPreferencesStackFile and there is no stack tPreferencesStackFile then
         revInternal__Log "Message", "Existing Preferences Stack Corrupted"
         
         put 1 into tIndex
         repeat while there is a file (tPreferencesStackFile & ".corrupt." & tIndex)
            add 1 to tIndex
         end repeat
         
         revInternal__Log "Message", "Moving Broken Stack to '" & tPreferencesStackFile & "'"
         
         rename file tPreferencesStackFile to (tPreferencesStackFile & ".corrupt." & tIndex)
      end if
      
      -- Next check to see that if there is a preferences file in the old location, if there
      -- there is no preferences stackfile in the new location.
      if there is no file tPreferencesStackFile and there is a file tOldPreferencesStackFile then
         revInternal__Log "Message", "Found preferences in old location, copying to new location."
         put url ("binfile:" & tOldPreferencesStackFile) into url ("binfile:" & tPreferencesStackFile)
      end if
      
      -- Next check to see if there is a preferences file in the new location under the
      -- name 'reventerprise'.
      if there is no file tPreferencesStackFile and there is a file tOldNewPreferencesStackFile then
         revInternal__Log "Message", "Found preferences in new location with old name, copying to new location."
         -- MM-2012-05-03: Fixed typo - changed tOldPreferencesStackFile to tOldNewPreferencesStackFile
         put url ("binfile:" & tOldNewPreferencesStackFile) into url ("binfile:" & tPreferencesStackFile)
      end if
      
      if there is no file tPreferencesStackFile then
         revInternal__Log "Message", "No Existing Preferences Stack Found"
         revInternal__Log "Message", "Copying template preferences to '" & tPreferencesStackFile & "'"
         lock messages
         if there is a stack "revpreferences" then
            delete stack "revpreferences"
         end if
         set the filename of stack "revpreferencestemplate" to tPreferencesStackFile
         set the name of stack "revpreferencestemplate" to "revpreferences"
         revInternal__ResetPreferences
         revInternal__SavePreferences
         unlock messages
      end if
      
      put the stackFiles of stack "Home" into tStackFiles
      put return & "revPreferences", tPreferencesStackFile after tStackFiles
      set the stackFiles of stack "Home" to tStackFiles
      
      revInternal__Log "Message", "Mapping Stack 'revpreferences.rev' to stackfile '" & tPreferencesStackFile & "'"
   else     
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
         if there is a stack "revpreferences" then
            delete stack "revpreferences"
         end if
         set the filename of stack "revpreferencestemplate" to tPreferencesStackFile7
         set the name of stack "revpreferencestemplate" to "revpreferences"
         revInternal__ResetPreferences
         revInternal__SavePreferences
         unlock messages
      end if
      
      put the stackFiles of stack "Home" into tStackFiles
      put return & "revPreferences", tPreferencesStackFile7 after tStackFiles
      set the stackFiles of stack "Home" to tStackFiles
      
      revInternal__Log "Message", "Mapping Stack 'revpreferences.rev' to stackfile '" & tPreferencesStackFile & "'"
   end if
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
   
   revInternal__Log "Leave", "Folders Setup"
end revInternal__SetupFolders

private command revInternal__SetupSplash
	palette stack "revSplash"
end revInternal__SetupSplash

-- MW-2011-03-10: Ensure certain preference settings reset to what 'new' defaults should be
--   (This was easier than attempting to edit revpreferences.rev which is very very slippery!)
command revInternal__ResetPreferences
   set the cREVToolsPaintToolsVisible of stack "revPreferences" to true
   set the cSEHidePalettes of stack "revPreferences" to false
   set the cSEHideMessageBox of stack "revPreferences" to false
end revInternal__ResetPreferences

--------------------------------------------------------------------------------
-- Internal Utility Functions
--
--

command revInternal__SavePreferences
   local tPreference 
   
   local tOldStackFileVersion
   put the stackFileVersion into tOldStackFileVersion
   
   if the buildnumber < 10000 then
      set the stackFileVersion to "2.7"
   else
      set the stackFileVersion to "7.0"
   end if
   
   lock messages
   -- MM-2014-02-22: [[ Bug 11442 ]] Saving the prefs stack when security permissions is true is not possible.
   try
      save stack "revPreferences"
   catch tError
   end try
   unlock messages
   
   set the stackFileVersion to tOldStackFileVersion
end revInternal__SavePreferences

private command revInternal__EnsureFolder pFolder
  revInternal__Log "Enter", "Ensuring Folder '" & pFolder & "'"
  
  local tPath, tComponent
  
  set the itemDelimiter to "/"
  repeat for each item tComponent in pFolder
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

local sLogIndent, sLogPath
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
   
   if sLogPath is empty then
      exit revInternal__Log
   end if
   
   open file sLogPath for text append
   
   if pType is "Leave" then
      subtract 2 from sLogIndent
   end if
   
   if pType is not "Message" then
      put pType && pMessage into pMessage
   end if
   
   repeat for each line tLine in pMessage
      if sLogIndent > 0 then
         write char 1 to sLogIndent of "                                " to file sLogPath
      end if
      write tLine & return to file sLogPath
   end repeat
   
   if pType is "Enter" then
      add 2 to sLogIndent
   end if
   
   close file sLogPath
end revInternal__Log

--------------------------------------------------------------------------------
-- Internal Initialisation Functions
--

command revInternal__InitialiseSystem
   local tSuccess
   
   revInternal__Log "Enter", "System Initialisation"
   
   put true into tSuccess
   
   if tSuccess then
      if the number of lines of the screenRect < 2 and item 4 of the screenRect < 600 then
         answer "Revolution requires a 1024x768 display for editing (but not playback). If you continue, you may not be able to use all of the editing tools." with "Continue" or "Quit"
         if it is "Quit" then
            put false into tSuccess
         end if
      end if
   end if
   
   if tSuccess then
      if the screenDepth < 15 then
         answer "Revolution requires a full-colour display." with "Ok"
         put false into tSuccess
      end if
   end if
   
   get the cCrashReportStyle of stack "revPreferences"
   if it is empty then
      get "Small"
   end if
   if sLicensePlatform is "Windows" and the word 2 of the systemVersion >= "5.1" and it is not "None" then
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
   put the cREVDevelopment of stack "Home" is not empty and the cREVDevelopment of stack "Home" into gREVDevelopment
   
   # OK-2009-09-16 : I don't think the above feature very useful, so added this instead.
   local tSettingsFile
   set the itemDelimiter to slash
   put item 1 to -2 of the filename of me & "/Development Settings.txt" into tSettingsFile
   set the itemDelimiter to comma
   
   local tSettings
   put url ("file:" & tSettingsFile) into tSettings
   split tSettings by return and tab
   
   if tSettings["developmentMode"] then
      put true into gREVDevelopment
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
   
   insert script of stack "revInitialisationLibrary" into back
   
   # BB-2014-09-30: New IDE library
   try	
      insert script of stack "revideextensionlibrary" into back 	 
      insert script of stack "revidedeveloperextensionlibrary" into back	
      insert script of stack "revsaveasstandalone" into back
      insert script of stack "revsaveasiosstandalone" into back
      insert script of stack "revsaveasandroidstandalone" into back
   catch tError 	 	
      answer "Error loading extensions library" & return & tError 	 	
   end try 	 	
   	    	 	
   try 	 	
      revInternal__LoadLibrary "revIDELibrary.8"	 
      insert script of stack "revidemessagehandler" into front 	 	
   catch tError 	 	
      answer "Error loading main IDE" & return & tError 	 	
   end try 
   
   revInternal__LoadLibrary "revBackScriptLibrary"
   
   # MW-2011-04-11: New deploy library for Android/iOS simulate/test support
   revInternal__LoadLibrary "revDeployLibrary"
   
   # OK-2008-03-11 : New debugger and metadata library
   revInternal__LoadLibrary "revDebuggerLibrary"
   revInternal__LoadLibrary "revMetadataLibrary"
   
   # OK-2008-06-11 : Documentation library
   insert the script of stack "revDocumentationLibrary" into back
   
   # OK-2008-11-25 : revOnline library
   insert the script of stack "revOnlineLibrary" into back
   
   revInternal__LoadLibrary "revIdeLibrary"
   revInternal__LoadLibrary "revLibUrl"
   revInternal__LoadLibrary "revCommonLibrary"
   revInternal__LoadLibrary "revPrintLibrary"
   revInternal__LoadLibrary "revAnimationLibrary"
   revInternal__LoadLibrary "revGeometryLibrary"
   revInternal__LoadLibrary "revXMLRPCLibrary"
   revInternal__LoadLibrary "revProfilesLibrary"
   revInternal__LoadLibrary "revDatabaseLibrary"
   revInternal__LoadLibrary "revTableLibrary"
   
   // EJB - New IDE Libraries
   
   try      
      insert script of stack "revCore" into back
   end try
   
   # MW-2010-10-13: [[ Bug 8600 ]] Make sure the handler lists of the rev frontscript, backscript and shortcuts script
   #    are all up to date (used by revNoMessages script).
   set the cREVGeneral["handlerlist"] of stack "revBackScriptLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revBackScriptLibrary")
   
   # Now we have the IDE scripts in place, initiaize the deployment platforms
   try
      revIDEDeployInitialize
   end try
   revInternal__Log "Leave", "Libraries Initialisation"
   
   return true
end revInternal__InitialiseLibraries

private command revInternal__SetupExternals
   revInternal__Log "Enter", "Externals Setup"
   
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
   
   switch sLicensePlatform
      case "MacOS X"
         set the stackFileType to "RevoRSTK"
         set the hidePalettes to true
         set the dontUseNS to false
         set the itemdelimiter to "."
         revInternal__Log "message", "Trying to set the default text of stack home"
         if item 2 of the systemVersion < 10 then
            set the textFont of stack "Home" to "Lucida Grande"
         else
            set the textFont of stack "Home" to "Helvetica Neue"
         end if
         
         set the textSize of stack "Home" to 11
         set the backColor of stack "Home" to empty
         
         hide stack "revMacCursors"    
         break
      case "Windows"
         set the hidePalettes to false
         
         if word 1 of the systemVersion is "NT" and word 2 of the systemVersion >= 6 and "Segoe UI" is among the lines of the fontNames then
            set the textFont of stack "Home" to "Segoe UI"
            set the textSize of stack "Home" to 12
         else if word 1 of the systemVersion is "NT" and word 2 of the systemVersion >= 5 and "Tahoma" is among the lines of the fontNames then
            set the textFont of stack "Home" to "Tahoma"
            set the textSize of stack "Home" to 11
         else
            set the textFont of stack "Home" to "MS Sans Serif"
            set the textSize of stack "Home" to 10
         end if
         set the backColor of stack "Home" to empty
         set the textSize of cd 1 of stack "Home" to empty
         
         if word 1 of the systemVersion is "Windows" then
            set the shellCommand to "command.com"
         else
            set the shellCommand to "cmd.exe"
         end if
         
         hide stack "revCursors"
         break
      case "Linux"
         set the hidePalettes to false
         set the textFont of stack "Home" to "Helvetica"
         set the textSize of stack "Home" to 12
         set the bottomColor of stack "Home" to empty
         set the textSize of cd 1 of stack "Home" to empty
         
         hide stack "revLinuxCursors"
         hide stack "revCursors"
         break
      default
         set the hidePalettes to false
         set the textFont of stack "Home" to "Helvetica"
         set the textSize of stack "Home" to 10
         set the bottomColor of stack "Home" to empty
         set the textSize of cd 1 of stack "Home" to empty
         
         hide stack "revLinuxCursors"
         hide stack "revCursors"
         break
   end switch
   
   if the lookAndFeel is "Windows 95" then 
      set the bottomColor of this stack to "128,128,128"
   else
      set the bottomColor of this stack to "172,172,172"
   end if
   
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
  
  global gREVShowStacks
  if the cShowRevolutionStacks of stack "revPreferences" is empty then
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
  revInternal__setSplashStatus revEnvironmentResourcesPath("Icon Libraries")
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
   
   # OK-2008-03-11 : Removed for now
   --  if the platform is "MacOS" then
   --    set the textFont of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to "Courier"
   --    set the textSize of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to 12
   --  else if the platform is "Win32" then
   --    set the textFont of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to "Courier New"
   --    set the textSize of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to 12
   --  else
   --    set the textFont of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to empty
   --    set the textSize of field "Script" of cd "revScript" of stack "revTemplateScriptEditor" to empty
   --  end if
   
   revInternal__Log "Leave", "Script Editor Initialisation"
   
   return true
end revInternal__InitialiseScriptEditor

command revInternal__InitialiseErrors
  revInternal__Log "Enter", "Errors Initialisation"
  
  set the cErrorsList of stack "revErrorDisplay" to the scriptExecutionErrors
  set the cScriptErrors of stack "revErrorDisplay" to the scriptParsingErrors
  
  revInternal__Log "Leave", "Errors Initialisation"
  
  return true
end revInternal__InitialiseErrors

command revInternal__InitialiseTools
  revInternal__Log "Enter", "Tools Initialisation"
  
  set the topLeft of stack "revTools" to the cToolsTopLeft of stack "revPreferences"
  palette "revTools"
  --choose pointer tool
  
  --revInternal__ConstrainStack "revTools"  
  
  revInternal__Log "Leave", "Tools Initialisation"
  
  return true
end revInternal__InitialiseTools

command revInternal__InitialiseIcons
  revInternal__Log "Enter", "Icons Initialisation"
  
  lock screen
  hide stack "revicons"
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
      palette stack tMenuBar
      unlock messages
   else
      toplevel stack tMenuBar
   end if
   set the defaultMenuBar to the long id of group "revMenuBar" of stack tMenuBar
   
   revInternal__ConstrainStack tMenuBar
   
   local tWindowRect
   put line (the screen of stack tMenuBar) of the working screenRects into tWindowRect
   if the right of stack "revTools" < 100 then put the right of stack "revTools" + 5 into item 1 of tWindowRect
   put the bottom of stack tMenuBar + 5 into item 2 of tWindowRect
   set the windowBoundingRect to tWindowRect
   
   revInternal__Log "Leave", "Menus Initialisation"
   
   if the platform is not "macos" or revIDEGetPreference("cToolbarText") or revIDEGetPreference("cToolbarIcons") then
      show stack tMenuBar
   end if
   
   return true
end revInternal__InitialiseMenus

command revInternal__InitialiseApplicationOverview
   revInternal__Log "Enter", "Application Overview Initialisation"
   
   if the cAppOverview of stack "revPreferences" then
      set the _ideoverride of stack "revApplicationOverview" to true
      toplevel "revApplicationOverview"
   end if
   
   // EJB
   if there is a stack "revProjectBrowser" then
      if the cIDEProjectBrowserOpen of stack "revPreferences" is not false then
         modeless "revProjectBrowser"
      end if
   end if
   
   revInternal__Log "Leave", "Application Overview Initialisation"
   
   return true
end revInternal__InitialiseApplicationOverview

command revInternal__InitialiseMessageBox
  revInternal__Log "Enter", "Message Box Initialisation"
  
  if the platform is among the items of "MacOS,Win32" then
    set the style of stack "Message Box" to "palette"
  else
    set the style of stack "Message Box" to "modeless"
  end if
  
  revInternal__Log "Leave", "Message Box Initialisation"
  
  return true
end revInternal__InitialiseMessageBox

command revInternal__InitialiseQuickTime
  revInternal__Log "Enter", "QuickTime Initialisation"
  
  if the cLoadQuickTimeOnStartup of stack "revPreferences" is not false then get the qtVersion
  
  revInternal__Log "Leave", "QuickTime Initialisation"
  
  return true
end revInternal__InitialiseQuickTime

command revInternal__InitialisePlugIns
   revInternal__Log "Enter", "Plug-Ins Initialisation"
   
   global gREVStartupList
   local tMode
   repeat for each line l in gREVStartUpList
      lock messages
      put the cREVLoadInfo["mode"] of stack l into tMode
      if tMode is empty then put "modeless" into tMode
      unlock messages
      
      # OK-2008-08-20 : Bug 6970 - This must be in a try in case one of the plugins throws an error when loaded.
      # For now we just ignore any errors the plugin may throw and allow it to launch anyway.
      try
         if tMode is "invisible" then
            go inv stack l
         else
            do "go stack" && quote & l & quote && "as" && tMode
         end if
      end try
   end repeat
   
   revIDEUpdatePlugins
   
   revInternal__Log "Leave", "Plug-Ins Initialisation"
   
   return true
end revInternal__InitialisePlugIns

command revInternal__InitialiseFinalSteps
   revInternal__Log "Enter", "Final Initialisation"
   
   revInternal__Log "Message", "Initialising Script Editor Palette Hiding"
   send "revInitialiseSEHidePalettes" to stack "revBackScriptLibrary"
   set the cREVScriptDebugMode of stack "revPreferences" to the cREVScriptDebugMode of stack "revPreferences"
   
   --the following *MUST* be the last item to avoid excess sending to overview as environment loads
   revInternal__Log "Message", "Installing Remaining Libraries"
   revInternal__LoadLibrary "revFrontScriptLibrary"
   set the cREVGeneral["handlerlist"] of stack "revFrontScriptLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revFrontScriptLibrary")
   
   revInternal__LoadLibrary "revShortCutsLibrary"
   set the cREVGeneral["handlerlist"] of stack "revShortCutsLibrary" to revInternal__FilterHandlerList(the revAvailableHandlers of stack "revShortCutsLibrary")
   //insert script of btn "revShortcuts" of cd 1 of stack "revLibrary" into front
   
   revInternal__Log "Message", "Setting up verbose debugging"
   send "revVerboseDebug" && the cVerboseDebug of stack "revPreferences" to stack "revFrontScriptLibrary"
   
   if the cBackDrop of stack "revPreferences" is not "none" and the cBackDrop of stack "revPreferences" is not empty then
      revInternal__Log "Message", "Setting up backdrop"
      set the backdrop to the cBackDrop of stack "revPreferences"
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
   --send "preOpenStack" to stack "revFrontScriptLibrary" in 5 milliseconds
   --send "preOpenStack" to stack "revFrontScriptLibrary" in 5 milliseconds
   
   revInternal__Log "Leave", "Final Initialisation"
   
   return true
end revInternal__InitialiseFinalSteps

# OK-2008-03-11
# Description
#   Initializes the debugger. This resets the breakpoints property to the appropriate
#   value for IDE startup. This command must be called after the preferences stack has 
#   been initialized.
command  revInternal__InitialiseDebugger
   send "revDebuggerInitialize" to stack "revDebuggerLibrary"
   return true
end  revInternal__InitialiseDebugger

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
    if the platform is "macos" and char 1 of the systemVersion is "1" then
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

function revEnvironmentPluginsPath
  return hookToolsPath("plugins", sToolsPath & "/Plugins")
end revEnvironmentPluginsPath

function revEnvironmentExternalsPath
  return hookToolsPath("externals", sToolsPath & "/Externals")
end revEnvironmentExternalsPath

function revEnvironmentRuntimePath
  return hookToolsPath("runtime", sToolsPath & "/Runtime")
end revEnvironmentRuntimePath

function revEnvironmentUserRuntimePath
  return sCustomizationPath & "/Runtime"
end revEnvironmentUserRuntimePath

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

function revEnvironmentUserPreferencesPath
  return sPreferencesPath
end revEnvironmentUserPreferencesPath

function revEnvironmentUserCachePath
  return sCachePath
end revEnvironmentUserCachePath

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

-- MW-2013-06-13: [[ CloneAndRun ]] Returns the path to the repo.
function revEnvironmentRepositoryPath
   return sRepositoryPath
end revEnvironmentRepositoryPath


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
    if char 1 of the systemVersion is 1 then
      put "MacOS X" into tPlatform
    else
      put "MacOS Classic" into tPlatform
    end if
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
