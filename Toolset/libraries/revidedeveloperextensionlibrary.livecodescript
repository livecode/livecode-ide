script "revIDEDeveloperExtensionLibrary"
local sExtensionDetailsA

constant kTestStackName = "LiveCode Extension Test Window"

private on __revIDEDeveloperExtensionSendWarning pWarning
   ideMessageSend "ideExtensionLog", "Warning:" && pWarning
end __revIDEDeveloperExtensionSendWarning

private on __revIDEDeveloperExtensionSendError pError
   ideMessageSend "ideExtensionLog", "Error:" && pError
end __revIDEDeveloperExtensionSendError

private on __revIDEDeveloperExtensionLog pLog
   ideMessageSend "ideExtensionLog", pLog
end __revIDEDeveloperExtensionLog

private on __revIDEDeveloperCompilationError pError, pFile
   local tLineNo, tChar, tEndChar, tLine
   # Parse out the error details to provide more meaningful feedback
   repeat for each line tErrLine in pError
      if matchText(tErrLine, ":([0-9]*):([0-9]*):", tLineNo, tChar) then
         put line tLineNo of url ("file:" & pFile) into tLine
         put tChar into tEndChar
         repeat while tChar is not 0 and char tChar - 1 of tLine is not " "
            subtract 1 from tChar
         end repeat
         ideMessageSend "ideExtensionLog", "Error: on line" && tLineNo && "(" & tLine & ")" & ":" && char tChar + 1 to tEndChar - 1 of tLine
      end if
   end repeat
   
   ideMessageSend "ideExtensionLog", "Error:" && pError
end __revIDEDeveloperCompilationError

private function __revIDEDeveloperExtensionShouldRecompile pFolder, pFile
   # To avoid excessive recompilation, test to see if the compiled module exists and is up to date.
   local tCompileInputs, tCompileOutputs, tNeedUpdate, tError
   
   put pFolder & slash & pFile into tCompileInputs[1]
   
   put pFolder & slash & "manifest.xml" into tCompileOutputs[1]
   put pFolder & slash & "module.lcm" into tCompileOutputs[2]
   
   put revIDEIsFilesetStale(tCompileInputs, tCompileOutputs, false, tError) \
         into tNeedUpdate
   
   if tNeedUpdate is false then
      -- read the file version string just to make sure
      -- in the future we should add an --outputversion option to lc-compile to automate this
      local tBytes
      open file tCompileOutputs[2] for binary read
      read from file tCompileOutputs[2] for 4
      -- Version 8.1 requires a LCB file version 1.0
      put not(byteToNum(byte 3 of it) is 1 and byteToNum(byte 4 of it) is 0) into tNeedUpdate
      close file tCompileOutputs[2]
   end if
   
   return tNeedUpdate is not false
end __revIDEDeveloperExtensionShouldRecompile

private on __revIDEDeveloperExtensionRemoveFolder pFolder
   local tDeveloperExtensionsFolders
   put revIDEGetPreference("cDeveloperExtensionsFolders") into tDeveloperExtensionsFolders
   
   set the itemdelimiter to slash
   local tRootFolder
   put item 1 to -2 of pFolder into tRootFolder
   
   local tLine
   put lineOffset(tRootFolder, tDeveloperExtensionsFolders) into tLine
   if tLine is not 0 then
      delete line tLine of tDeveloperExtensionsFolders
      revIDESetPreference "cDeveloperExtensionsFolders", tDeveloperExtensionsFolders
   end if
end __revIDEDeveloperExtensionRemoveFolder

private on __revIDEDeveloperExtensionAddFolder pFolder
   local tDeveloperExtensionsFolders
   put revIDEGetPreference("cDeveloperExtensionsFolders") into tDeveloperExtensionsFolders
   
   set the itemdelimiter to slash
   local tRootFolder
   put item 1 to -2 of pFolder into tRootFolder
   if tDeveloperExtensionsFolders is empty then
      put tRootFolder into tDeveloperExtensionsFolders
   else
      if tRootFolder is not among the lines of tDeveloperExtensionsFolders then
         put return & tRootFolder after tDeveloperExtensionsFolders
      end if
   end if
   
   revIDESetPreference "cDeveloperExtensionsFolders", tDeveloperExtensionsFolders
end __revIDEDeveloperExtensionAddFolder

/*
Summary: Returns an array of details of the extensions found in user folders
Returns (array):
{ key: The path to the folder containing the extensions
value (array): The array of details pertaining to the extension
{ key: "name"
value: The extension ID
key: "title"
value: The title of the extension
key: "author"
value: The author of the extension
key: "api"
value: An array describing the documented elements of this extension
key: "guide"
value: The user guide
key: "icon"
value: The path to the icon of this extension
key: "retina_icon"
value: The path to the retina icon of this extension } } 
*/
function revIDEDeveloperExtensions pFolder
   local tExtensionDetailsA
   
   local tFolders
   
   if pFolder is empty then
      if not revEnvironmentIsInstalled() then
         # Look for extension examples in git repo.
         put revEnvironmentRepositoryPath() & slash & "extensions" & slash & "widgets" into tFolders 
         put return & revEnvironmentRepositoryPath() & slash & "extensions" & slash & "libraries" after tFolders
      end if
      
      # Look for extension examples in previously selected user folders.
      local tUserFolders
      put revIDEGetPreference("cDeveloperExtensionsFolders") into tUserFolders
      repeat for each line tLine in tUserFolders
         if tLine is among the lines of tFolders then next repeat
         
         if tFolders is empty then
            put tLine into tFolders
         else
            put return & tLine after tFolders
         end if
      end repeat
   else
      put pFolder into tFolders
   end if
   
   local tFolder, tExtensionFolders, tExtensionFolder, tFiles, tExtension
   
   local tFolderHasModule
   repeat for each line tFolder in tFolders
      put false into tFolderHasModule
      if tFolder is empty then
         next repeat
      end if
      put folders(tFolder) into tExtensionFolders
      repeat for each line tExtensionFolder in tExtensionFolders
         if tExtensionFolder is ".." then 
            next repeat
         end if
         local tExtensionA
         # On first run, don't compile.
         put revIDEDeveloperExtensionNoCompile(tFolder & slash & tExtensionFolder) into tExtensionA
         if tExtensionA is not empty then
            put tExtensionA into tExtensionDetailsA[tFolder & slash & tExtensionFolder]
            put true into tFolderHasModule
         end if
      end repeat
      if tFolderHasModule is false then
         __revIDEDeveloperExtensionRemoveFolder tFolder
      end if
   end repeat
   
   return tExtensionDetailsA
end revIDEDeveloperExtensions

private function __revIDEDeveloperExtensionFetchModuleInFolder pFolder
   local tFiles
   put files(pFolder) into tFiles
   filter tFiles with "*.lcb"
   
   local tFile
   # For now, if there are multiple lcb files in one folder, just use the first one.
   if the number of lines of tFiles > 1 then
      put replaceText(tFiles, return, ",") into tFiles
      __revIDEDeveloperExtensionSendError "multiple lcb files in folder" && pFolder & ":" && tFiles
      return empty
   else
      put tFiles into tFile
   end if
   return tFile
end __revIDEDeveloperExtensionFetchModuleInFolder

function revIDEDeveloperExtensionNoCompile pFolder
   local tFile
   put __revIDEDeveloperExtensionFetchModuleInFolder(pFolder) into tFile
   
   local tDataA
   if there is a file (pFolder & slash & "manifest.xml") then
      __FetchManifest (pFolder & slash & "manifest.xml"), tDataA
   else if there is not a file (pFolder & slash & tFile) then
      return empty
   end if
   
   if the result is not empty then
      put tFile into tDataA["file"]
   end if
   return tDataA
end revIDEDeveloperExtensionNoCompile

private function __revIDEDeveloperExtensionFetchFolderDetails pFolder, pFile
   local tDetailsA
   
   # Check timestamps to see if API  is out of date.
   local tLastGenerated, tLastModified, tAPIFolder
   if there is a folder (pFolder & slash & "docs" & slash & "api") then
      put pFolder & slash & "docs" & slash & "api" into tAPIFolder
   else
      put pFolder into tAPIFolder
   end if
   
   if there is a file pFile then
      revIDEExtensionUpdateAPI tAPIFolder, pFile
      
      local tAPI
      if the result is empty then
         # Check to see if we've already parsed to a docs library array
         put sExtensionDetailsA[pFolder]["api"] into tAPI
      end if	
      
      if tAPI is empty then
         local tData
         put url ("binfile:" & pFolder & slash & "api.lcdoc") into tData
         put textDecode(tData, "utf-8") into tData
         
         # If either we had to generate the new docs data or get it from the file, parse to a docs library array
         local tLibraryA
         dispatch function "revDocsParseDocTextToLibraryArray" to stack "revDocsParser" with tData, tDetailsA["name"], tDetailsA["author"]
         put the result into tLibraryA
         put tLibraryA["doc"] into tDetailsA["api"]
         put tAPIFolder & slash & "api.lcdoc" into tDetailsA["api_file"]
      end if
   end if
   
   if there is a file (pFolder & slash & "support" & slash & "icon.png") then
      put (pFolder & slash & "support" & slash & "icon.png") into tDetailsA["icon"]
   else if there is a file  (pFolder & slash & "icon.png") then
      put (pFolder & slash & "icon.png") into tDetailsA["icon"]
   else
      put empty into tDetailsA["icon"]
   end if
   
   if there is a file (pFolder & slash & "support" & slash & "icon@extra-high.png") then
      put (pFolder & slash & "support" & slash & "icon@extra-high.png") into tDetailsA["retina_icon"]
   else if there is a file (pFolder & slash & "icon@extra-high.png") then
      put (pFolder & slash & "icon@extra-high.png") into tDetailsA["retina_icon"]
   else
      put empty into tDetailsA["retina_icon"]
   end if
   
   local tGuide, tGuideFile
   if there is a file (pFolder & slash & "docs" & slash & "guide" & slash & "guide.md") then
      put pFolder & slash & "docs" & slash & "guide" & slash & "guide.md" into tGuideFile
   else if there is a file (pFolder & slash & "guide.md") then
      put pFolder & slash & "guide.md" into tGuideFile
   end if
   
   if tGuideFile is not empty then
      put tGuideFile into tDetailsA["guide_file"]
      put url ("binfile:" & tGuideFile) into tGuide
      put textDecode(tGuide, "utf-8") into tGuide
   end if 
   
   put tGuide into tDetailsA["guide"]
   
   // AL-2015-02-23: [[ Bug 14552 ]] Find resource folder and return details
   local tResourceFolder, tResources
   put pFolder & slash & "resources" into tResourceFolder
   if there is a folder tResourceFolder then
      put __revIDEDeveloperExtensionListResourcesRecursive(tResourceFolder, "") into tResources
      put tResources into tDetailsA["resources"]
   end if
   
   # Default script
   put revIDEExtensionFetchDefaultScript(pFolder, tDetailsA["name"], false) into tDetailsA["defaultscript"]
   if tDetailsA["defaultscript"] is not empty then
      put pFolder & "/support/defaultscript.livecodescript" into tDetailsA["defaultscript_file"]
   end if
   return tDetailsA 
end __revIDEDeveloperExtensionFetchFolderDetails

private function __revIDEDeveloperExtensionListResourcesRecursive pFolder, pPrefix
   local tResources, tResource, tPrefix
   if pPrefix is not empty then
      put pPrefix & slash into tPrefix
   end if
   
   # Add files to the list of resources
   repeat for each line tResource in files(pFolder)
      if tResource begins with "." then next repeat
      if tResources is empty then
         put tPrefix & tResource into tResources
      else
         put return & tPrefix & tResource after tResources
      end if
   end repeat
   
   # Add folders to the list of resources
   repeat for each line tResourceFolder in folders(pFolder)
      if tResourceFolder begins with "." then next repeat
      local tRecursive
      put __revIDEDeveloperExtensionListResourcesRecursive(pFolder & slash & tResourceFolder, tPrefix & tResourceFolder) into tRecursive
      if tRecursive is not empty then
         if tResources is empty then
            put tRecursive into tResources
         else
            put return & tRecursive after tResources
         end if
      end if
   end repeat
   
   return tResources
end __revIDEDeveloperExtensionListResourcesRecursive

private command __CompilePackage pFolder, pPackageFolder, @xDetailsA
   local tPackageDataA
   __FetchManifest (pPackageFolder & slash & "manifest.xml"), tPackageDataA
   
   -- inclusions should be listed in dependency order so we must stop
   -- compiling when we hit our folder as anything listed after may depend
   -- on the target
   local tIndex
   repeat with tIndex = 1 to the number of elements in tPackageDataA["includes"]
      if tPackageDataA["includes"][tIndex]["name"] begins with (tPackageDataA["name"] & ".") then
         local tName
         put tPackageDataA["includes"][tIndex]["name"] into tName
         put empty into char 1 to length(tPackageDataA["name"] & ".") of tName
         
         if pFolder is not (pPackageFolder & slash & tName) then
            local tFile
            put __revIDEDeveloperExtensionFetchModuleInFolder(pPackageFolder & slash & tName) into tFile
            
            if tFile is not empty then
               if not __revIDEDeveloperExtensionShouldRecompile(pPackageFolder & slash & tName, tFile) then
                  __revIDEDeveloperExtensionLog "Skipping recompilation of" && pPackageFolder & slash & tName & slash & "module.lcm - module is up to date"
               else
                  # The compiled module or manifest is not up to date, so compile.
                  __revIDEDeveloperExtensionLog "Compiling module" && pFolder & slash & tFile
                  __revIDEDeveloperCompileModule pPackageFolder & slash & tName & slash & tFile, pPackageFolder & slash & tName, pPackageFolder
                  
                  if the result is not empty then
                     # This may be better as a warning, and try to parse info direct from the file.
                     __revIDEDeveloperExtensionSendError the result
                     exit __CompilePackage
                  end if
               end if
            end if
            
            local tMetadataA
            __FetchManifest (pPackageFolder & slash & tName & slash & "manifest.xml"), tMetadataA
            put pPackageFolder & slash & tName into tMetadataA["folder"]
            put tMetadataA into xDetailsA["requires load"][tIndex]
         else
            exit __CompilePackage
         end if
      else
         __revIDEDeveloperExtensionSendError "Inclusions names should begin with package name:" && tPackageDataA["name"]
         exit __CompilePackage
      end if
   end repeat
end __CompilePackage

private function __revIDEDeveloperExtensionDetails pFolder, pPackageFolder
   if pPackageFolder is empty then
      put pFolder into pPackageFolder
   end if
   
   local tFile
   put __revIDEDeveloperExtensionFetchModuleInFolder(pFolder) into tFile
   
   local tDetailsA
   put __revIDEDeveloperExtensionFetchFolderDetails(pFolder, tFile) into tDetailsA
   
   # compile dependencies if required
   if pFolder is not pPackageFolder then
      __CompilePackage pFolder, pPackageFolder, tDetailsA
   end if
   
   if tFile is not empty then
      put tFile into tDetailsA["file"]
      if not __revIDEDeveloperExtensionShouldRecompile(pFolder, tFile) then
         __revIDEDeveloperExtensionLog "Skipping recompilation of" && pFolder & slash & "module.lcm - module is up to date"
         # The stored info is up to date.
         if sExtensionDetailsA[pFolder] is not empty then
            union tDetailsA with sExtensionDetailsA[pFolder]
            put tDetailsA into sExtensionDetailsA[pFolder]
            return sExtensionDetailsA[pFolder]
         end if
         # The compiled module and manifest are up to date, but we haven't fetched the information yet.
      else
         # The compiled module or manifest is not up to date, so compile.
         __revIDEDeveloperExtensionLog "Compiling module" && pFolder & slash & tFile
         __revIDEDeveloperCompileModule pFolder & slash & tFile, pFolder, pPackageFolder
         
         if the result is not empty then
            # This may be better as a warning, and try to parse info direct from the file.
            __revIDEDeveloperExtensionSendError the result
            return tDetailsA
         end if
      end if
   end if
   
   __revIDEDeveloperExtensionLog "Fetching metadata from" && pFolder & slash & "manifest.xml"
   local tMetadataA
   __FetchManifest (pFolder & slash & "manifest.xml"), tMetadataA
   union tDetailsA with tMetadataA recursively
   
   if the result is not empty then
      __revIDEDeveloperExtensionSendError the result
      return tDetailsA
   end if
   
   put tDetailsA into sExtensionDetailsA[pFolder]
   return sExtensionDetailsA[pFolder]
   
end __revIDEDeveloperExtensionDetails

on revIDEDeveloperExtensionAddResourceFile pExtensionFolder, pResourcePath, pType
   if there is not a file pResourcePath then
      __revIDEDeveloperExtensionSendError the result
      exit revIDEDeveloperExtensionAddResourceFile
   end if
   
   local tResourceFolder
   put pExtensionFolder & slash & "resources" into tResourceFolder
   if there is not a folder tResourceFolder then
      create folder tResourceFolder
   end if
   
   set the itemdelimiter to slash
   switch pType
      case "icon"
         revCopyFile pResourcePath, pExtensionFolder & slash & "icon.png"
      case "retina_icon"
         revCopyFile pResourcePath, pExtensionFolder & slash & "icon@extra-high.png"
      case "api"
         revCopyFile pResourcePath, pExtensionFolder & slash & "api.lcdoc"
      case "guide"
         revCopyFile pResourcePath, pExtensionFolder & slash & "guide.md"
      default
         revCopyFile pResourcePath, tResourceFolder & slash & item -1 of pResourcePath
   end switch
   
   if the result is not empty then
      __revIDEDeveloperExtensionSendError "Failed to copy file:" && the result
   end if
end revIDEDeveloperExtensionAddResourceFile

on revIDEDeveloperExtensionAddResourceFolder pExtensionFolder, pResourceFolder
   if there is not a folder pResourceFolder then
      __revIDEDeveloperExtensionSendError "No such folder:" && pResourceFolder
      exit revIDEDeveloperExtensionAddResourceFolder
   end if
   
   local tResourceFolder
   put pExtensionFolder & slash & "resources" into tResourceFolder
   if there is not a folder tResourceFolder then
      create folder tResourceFolder
   end if
   
   revCopyFolder pResourceFolder, pExtensionFolder & slash & "resources"
   if the result is not empty then
      __revIDEDeveloperExtensionSendError "Failed to copy folder:" && the result
   end if
end revIDEDeveloperExtensionAddResourceFolder

on revIDEDeveloperExtensionTest pPath, pPackagePath
   local tDetailsA
   put __revIDEDeveloperExtensionDetails(pPath, pPackagePath) into tDetailsA
   
   if tDetailsA["file"] is empty then
      __revIDEDeveloperExtensionSendError "No extension to test in" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   # AL-2015-07-15: [[ Bug ]] If the details of the extension doesn't include an ID, then the compile failed
   if tDetailsA["name"] is empty then
      __revIDEDeveloperExtensionSendError "Could not compile module" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   if there is not a file (pPath & slash & "module.lcm") then
      __revIDEDeveloperExtensionSendError "No compiled module in" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   __revIDEDeveloperExtensionLog "Launching in Test Window"
   
   __revIDEDeveloperExtensionLaunchTestStack pPath, tDetailsA
end revIDEDeveloperExtensionTest

private function __testStackRects
   local tDataA
   if there is a stack kTestStackName then
      put the rect of stack kTestStackName into tDataA["rect"]
      if there is a widget 1 of stack kTestStackName then
         put the rect of widget 1 of stack kTestStackName into tDataA["wrect"]
      end if
      return tDataA
   end if
   
   local tScreenRect
   put the working screenrect into tScreenRect
   
   local tX, tY
   if the left of this stack + 200 < (item 3 of tScreenRect) / 2 then
      put the right of this stack + 200 into tX
   else
      put the left of this stack - 200 into tX
   end if
   put item 2 of the loc of this stack into tY
   put tX & comma & tY into tDataA["loc"]
   return tDataA
end __testStackRects

private function __testStackScript
   local tScript
   put "on closeStackRequest;revIDEDeveloperExtensionClearTestStack;exit closeStackRequest;end closeStackRequest;on saveStackRequest;exit saveStackRequest;end saveStackRequest" into tScript
   replace ";" with return in tScript
   return tScript
end __testStackScript

private on __revIDEDeveloperExtensionLaunchTestStack pPath, pDetailsA
   local tRectsA
   put __testStackRects() into tRectsA
   
   if there is a stack kTestStackName then
      revIDEDeveloperExtensionClearTestStack
   end if
   
   revIDEDeveloperExtensionCreateTestStack pPath, tRectsA, pDetailsA
end __revIDEDeveloperExtensionLaunchTestStack

on revIDEDeveloperExtensionClearTestStack
   send "__revIDEDeveloperExtensionDoClearTestStack" to me in 0 millisecs
end revIDEDeveloperExtensionClearTestStack

on revIDEDeveloperExtensionCreateTestStack pPath, pRectsA, pDetailsA
      send "__revIDEDeveloperExtensionDoCreateTestStack pPath, pRectsA, pDetailsA" to me in 0 millisecs
end revIDEDeveloperExtensionCreateTestStack

on __revIDEDeveloperExtensionDoCreateTestStack pPath, tRectsA, pDetailsA
   local tIndex
   repeat with tIndex = 1 to the number of elements in pDetailsA["requires load"]
      revIDEExtensionLoad pDetailsA["requires load"][tIndex]["name"], pDetailsA["requires load"][tIndex]["folder"], pDetailsA["requires load"][tIndex]["version"]
   end repeat
   
   revIDEExtensionLoad pDetailsA["name"], pPath, pDetailsA["version"]
   
   local tResult
   put the result into tResult
   if tResult is not empty then
      __revIDEDeveloperExtensionSendError tResult
      exit __revIDEDeveloperExtensionDoCreateTestStack
   end if
   lock screen
   
   if there is a stack (pPath & slash & "test.livecode") then
      go stack (pPath & slash & "test.livecode") 
   else
      lock messages
      create stack kTestStackName
      if tRectsA["rect"] is not empty then
         set the rect of stack kTestStackName to tRectsA["rect"]
      else
         set the loc of stack kTestStackName to tRectsA["loc"]
      end if
      set the destroyStack of stack kTestStackName to true
      set the title of it to pDetailsA["title"]
      set the script of it to __testStackScript()
      go stack kTestStackName
      unlock messages
   end if
   
   --!TODO - support other extension types
   switch pDetailsA["type"]
      case "widget"
         lock messages
         create widget as pDetailsA["name"]
         
         if there is not a widget 1 of stack kTestStackName then
            __revIDEDeveloperExtensionSendError "failed to create widget" && pDetailsA["name"]
            __revIDEDeveloperExtensionDoClearTestStack
            exit __revIDEDeveloperExtensionDoCreateTestStack
         end if
         
         if tRectsA["wrect"] is not empty then
            set the rect of widget 1 of stack kTestStackName to tRectsA["wrect"]
         end if
         
         unlock messages
         break
   end switch
   
   set the cCurExtensionDetails of stack kTestStackName to pDetailsA
   unlock screen
end __revIDEDeveloperExtensionDoCreateTestStack

on __revIDEDeveloperExtensionDoClearTestStack
   if there is not a stack kTestStackName then
      exit __revIDEDeveloperExtensionDoClearTestStack
   end if
   
   repeat while there is a widget 1 of stack kTestStackName 
      delete widget 1 of stack kTestStackName
   end repeat
   
   local tDetailsA
   put the cCurExtensionDetails of stack kTestStackName into tDetailsA
   delete stack kTestStackName
   
   if tDetailsA["name"] is not empty then
      __revIDEDeveloperExtensionLog "Unloading..."
      local tIndex
      repeat with tIndex = the number of elements in tDetailsA["requires load"] down to 1
         revIDEExtensionUnoad tDetailsA["requires load"][tIndex]["name"]
      end repeat
      
      __revIDEDeveloperExtensionUnload tDetailsA["name"]
   end if
end __revIDEDeveloperExtensionDoClearTestStack

local sInstalledExtension
on __revIDEDeveloperExtensionUnload pExtension
   # Don't unload if we have installed
   if pExtension is not sInstalledExtension then
      revIDEExtensionUnload pExtension
   end if
end __revIDEDeveloperExtensionUnload

on revIDEDeveloperExtensionInstall pFolder
   local tPackage
   __BuildPackage pFolder, "", tPackage
   revIDEInstallExtension tPackage
   put pFolder & slash & "module.lcm" into sInstalledExtension
end revIDEDeveloperExtensionInstall

on revIDEDeveloperExtensionUninstall pPath
   local tDetailsA
   put revIDEDeveloperExtension(pPath) into tDetailsA
   
   if tDetailsA["name"] is empty then
      __revIDEDeveloperExtensionSendError "Extension id lost from" && pPath & ": cannot uninstall"
      exit revIDEDeveloperExtensionUninstall
   end if
   
   revIDEUninstallExtension tDetailsA["name"]
   
end revIDEDeveloperExtensionUninstall

on revIDEDeveloperExtensionEditScript pFolder
   local tFile
   put pFolder & slash & __revIDEDeveloperExtensionFetchModuleInFolder(pFolder) into tFile
   
   # AL-2015-04-01: [[ Bug 15130 ]] First check to see if there is an existing association
   launch document tFile
   if the result is not empty then
      # AL-2015-04-01: [[ Bug 15130 ]] Check to see if the text editor preference is set
      local tEditor
      put revIDEGetPreference("LCB_textEditor") into tEditor
      if tEditor is not empty then
         launch tFile with tEditor
      end if
   end if
   
   if the result is "no association" or the result is "request failed" then
      answer file "Select text editor..."
      if it is not empty then
         launch tFile with it
      end if
   end if
   
   if the result is not empty then
      __revIDEDeveloperExtensionSendError "Could not open" && tFile & ":" && the result
   else if it is not empty then
      # AL-2015-04-01: [[ Bug 15130 ]] If the new text editor launch was successful, set the preference
      revIDESetPreference "LCB_textEditor", it
   end if
end revIDEDeveloperExtensionEditScript

on revIDEDeveloperExtensionOpen pFolder
   __revIDEDeveloperExtensionAddFolder pFolder
   return revIDEDeveloperExtension(pFolder)
end revIDEDeveloperExtensionOpen

function __revIDEDeveloperExtensionFetchWidgetTemplateFile
   return url ("file:" & revIDESpecialFolderPath("Toolset") & slash & "widget_template.txt")
end __revIDEDeveloperExtensionFetchWidgetTemplateFile

function __revIDEDeveloperExtensionFetchTemplate pDataA
   local tTemplate
   if pDataA["type"] is "widget" then
      put __revIDEDeveloperExtensionFetchWidgetTemplateFile() into tTemplate
   else
      put __revIDEDeveloperExtensionFetchLibraryTemplateFile() into tTemplate
   end if
end __revIDEDeveloperExtensionFetchTemplate

on revIDEDeveloperExtensionNew pDataA
   local tTemplate
   put __revIDEDeveloperExtensionFetchTemplate(pDataA) into tTemplate
   if tTemplate is empty then
      return empty
   end if
   put merge(tTemplate) into url("file:" & pDataA["path"] & slash & pDataA["name"] & ".lcb")
end revIDEDeveloperExtensionNew

private on __FetchManifest pManifestPath, @rDataA
   ideExtensionParseManifest pManifestPath, rDataA
   if the result is not empty then
      local tResult
      put the result into tResult
      __revIDEDeveloperExtensionSendError tResult
      return tResult for error
   end if
   
   return empty for value
end __FetchManifest

private function shellFormat pArg, pSwitch
   local tOutput
   
   if pSwitch is not empty then
      put "--" & pSwitch & " " into tOutput
   end if
   
   return tOutput & quote & pArg & quote & " "
end shellFormat

private function __revIDEDDeveloperExtensionResourcePath
   if revEnvironmentIsInstalled() is false then
      return revEnvironmentBinariesPath()
   else
      return revIDESpecialFolderPath("Toolchain")
   end if
end __revIDEDDeveloperExtensionResourcePath

private function __revIDEDeveloperExtensionCompilerPath
   # The actual compile command
   if the platform is "win32" then
      return __revIDEDDeveloperExtensionResourcePath() & slash & "lc-compile.exe"
   else
      return __revIDEDDeveloperExtensionResourcePath() & slash & "lc-compile"
   end if
end __revIDEDeveloperExtensionCompilerPath

private command __revIDEDeveloperCompileModule pFile, pTargetFolder, pPackageFolder
   # The manifest is currently always generated from the source
   if there is a file (pTargetFolder & slash & "manifest.xml") then
      delete file (pTargetFolder & slash & "manifest.xml")
   end if
   
   # Build the shell command
   local tShellCommand
   put shellFormat(__revIDEDeveloperExtensionCompilerPath()) into tShellCommand
   
   # The folder to put the .lci file
   put shellFormat(pPackageFolder, "modulepath") after tShellCommand
   
   # The built-in module path
   put shellFormat(__revIDEDDeveloperExtensionResourcePath() & slash & "modules/lci", "modulepath") after tShellCommand
   
   # Installed module path
   put shellFormat(revIDESpecialFolderPath("user extensions") & slash & "interface", "modulepath") after tShellCommand
   
   # The manifest target
   put shellFormat(pTargetFolder & slash & "manifest.xml", "manifest") after tShellCommand
   
   # The output
   put shellFormat(pTargetFolder & slash & "module.lcm", "output") after tShellCommand
   
   # The target .lcb file
   put shellFormat(pFile) after tShellCommand
   
   # AL-2015-06-15: [[ Bug 15001 ]] Don't show console window when executing shell command
   local tHideConsoleWindows
   put the hideConsoleWindows into tHideConsoleWindows
   set the hideConsoleWindows to true
   
   local tShellOutput, tShellResult
   put shell(tShellCommand) into tShellOutput
   put the result into tShellResult
   
   set the hideConsoleWindows to tHideConsoleWindows
   
   if tShellResult is not 0 then
      __revIDEDeveloperCompilationError tShellOutput
      return "failed to compile module"
   end if
   
   __revIDEDeveloperExtensionLog tShellOutput
   
   if there is not a file (pTargetFolder & slash & "module.lcm") then
      return "failed to compile module"
   end if
   
   if there is not a file (pTargetFolder & slash & "manifest.xml") then
      return "failed to generate manifest"
   end if
   
   return empty
end __revIDEDeveloperCompileModule

on revIDEDeveloperExtensionBuildPackage pFolder
   local tBuiltLocation
   __BuildPackage pFolder, "", tBuiltLocation
   # AL-2015-05-22: [[ Bug 14919 ]] Don't display success dialog when package building fails
   if the result is empty then
      answer "Package" && tBuiltLocation && "built successfully"
   end if
end revIDEDeveloperExtensionBuildPackage

private command __PackageContent pDetailsA, pFolder, pRootFolder, @xFiles, @xFolders
   switch pDetailsA["type"]
      case "package"
         break
      case "widget"
      case "library"
      case "module"
         if there is not a file (pFolder & slash & "module.lcm") then
            return "Error: missing file" && (pFolder & slash & "module.lcm") for error
         end if
         put pRootFolder & "module.lcm" into xFiles[pFolder & slash & "module.lcm"]
         break
   end switch
   
   put "manifest.xml" into xFiles[pFolder & slash & "manifest.xml"]
   
   local tFolders
   repeat for each word tFolder in "resources code"
      if there is folder (pFolder & slash & tFolder) then
         put tFolder into xFolders[pFolder & slash & tFolder]
      end if
   end repeat
   
   # AL-2015-05-22: [[ Bug 14919 ]] Use default widget and library icons if none are provided
   if pDetailsA["svgicon"] is empty then
      if pDetailsA["icon"] is empty or there is not a file pDetailsA["icon"] then
         answer file "Select icon file" with type "|png|"
         if it is empty then
            __revIDEDeveloperExtensionLog "Using default icon"
            get revIDEDefaultExtensionIcon(pDetailsA["type"], false)
         end if
         put it into pDetailsA["icon"]
      end if
      put "support/icon.png" into xFiles[pDetailsA["icon"]]
   end if
   
   if pDetailsA["svgicon"] is empty then
      if pDetailsA["retina_icon"] is empty or there is not a file pDetailsA["retina_icon"] then
         answer file "Select retina icon file" with type "|png|"
         if it is empty then
            __revIDEDeveloperExtensionLog "Using default retina icon"
            get revIDEDefaultExtensionIcon(pDetailsA["type"], true)
         end if
         put it into pDetailsA["retina_icon"]
      end if
      put "support/icon@extra-high.png" into xFiles[pDetailsA["icon"]]
   end if
   
   if there is a file pDetailsA["guide_file"] then
      put "docs/guide/guide.md" into xFiles[pDetailsA["guide_file"]]
   end if
   
   if there is a file pDetailsA["api_file"] then
      put "docs/api/api.lcdoc" into xFiles[pDetailsA["api_file"]]
   else
      __revIDEDeveloperExtensionSendWarning "docs formatting error. Docs may be empty"
   end if
   
   # AL-2015-03-18: [[ Bug 15007 ]] Include interface file if present
   local tInterfaceFiles
   put files(pFolder) into tInterfaceFiles
   filter tInterfaceFiles with "*.lci"
   local tFile
   repeat for each line tFile in tInterfaceFiles
      put tFile into xFiles[pFolder & slash & tFile]
   end repeat
   
   if there is a file pDetailsA["defaultscript_file"] then
      put "support/defaultscript.livecodescript" into xFiles[pDetailsA["defaultscript_file"]]
   end if
end __PackageContent

private command __BuildPackage pFolder, pTargetFolder, @rBuiltLocation
   local tTargetFolder
   if pTargetFolder is empty then
      put pFolder into tTargetFolder
   else
      put pTargetFolder into tTargetFolder
   end if
   
   local tDetailsA
   put revIDEDeveloperExtension(pFolder) into tDetailsA
   
   local tTargetName
   if tDetailsA["name"] is empty then
      __revIDEDeveloperExtensionSendError "no name found in " && pFolder & slash & "manifest.xml"
      return "no id found"
   end if
   put tDetailsA["name"] into tTargetName
   
   local tTargetVersion
   if tDetailsA["version"] is empty then
      __revIDEDeveloperExtensionSendError "no version found in " && pFolder & slash & "manifest.xml"
      return "no version found"
   end if
   put tDetailsA["version"] into tTargetVersion
   
   local tFiles, tFolders
   __PackageContent tDetailsA, pFolder, "", tFiles, tFolders
   
   local tArchive
   put tTargetFolder & slash & tTargetName & "." & tTargetVersion & ".lce" into tArchive
   
   if there is a file tArchive then
      delete file tArchive
   end if
   revZipOpenArchive tArchive, "write"
   
   if the result begins with "ziperr" then
      __revIDEDeveloperExtensionSendError "couldn't open zip archive" &&  tArchive
      return "couldn't open zip archive" && tArchive for error
   end if
   
   local tError
   put __AddSpecifiedFilesToPackage(tArchive, tFiles, tFolders) into tError
   
   revZipCloseArchive tArchive
   
   if tError is empty then
      if the result begins with "ziperr" then
         put "Error: couldn't close zip archive" into tError
      end if
   end if
   
   if tError is not empty then
      __revIDEDeveloperExtensionSendError tError
      return tError
   end if
   
   put tArchive into rBuiltLocation
   return empty
end __BuildPackage

private function __AddSpecifiedFilesToPackage pArchive, pFiles, pFolders
   local tError
   
   # Add files
   local tFile
   if tError is empty then
      repeat for each key tFile in pFiles
         revZipAddItemWithFile pArchive, pFiles[tFile], tFile
         if the result begins with "ziperr" then
            put "couldn't add file:" && tFile into tError
            exit repeat
         end if
      end repeat
   end if
   
   # Add folders
   if tError is empty then
      repeat for each key tFolder in pFolders
         local tFiles
         put __revIDEDeveloperExtensionListResourcesRecursive(tFolder, "") into tFiles
         repeat for each line tLine in tFiles
            revZipAddItemWithFile pArchive, pFolders[tFolder] & slash & tLine, tFolder & slash & tLine
            
            if the result begins with "ziperr" then
               __revIDEDeveloperExtensionSendWarning "couldn't add resource" && tFolder & slash & tLine
            end if
         end repeat
      end repeat
   end if
   
   return tError
end __AddSpecifiedFilesToPackage

on revIDEDeveloperExtensionEditDefaultScript pFolder
   local tDefaultScript, tTargetStack
   put pFolder & "/support/defaultscript.livecodescript" into tDefaultScript
   
   local tExpectedName
   put sExtensionDetailsA[pFolder]["name"] & ".__DefaultScript" into tExpectedName
   if there is a file tDefaultScript then
      try
         # If we have a valid stack, open it and edit the script
         open stack tDefaultScript
         put the long id of stack tDefaultScript into tTargetStack
         revIDEEditScriptOfObject tTargetStack
      catch tError
         # Otherwise, try to use the contents of the file as the script of a stack
         local tContents
         put textDecode(url( "binfile:" & tDefaultScript), "utf-8") into tContents
         revIDENewScriptOnlyStackWithScript tExpectedName, tContents
         put the result into tTargetStack
         set the filename of tTargetStack to tDefaultScript
      end try
   else
      # If there is no file, create a new one.
      revIDENewScriptOnlyStack tExpectedName
      put the result into tTargetStack
   end if
   return tTargetStack
end revIDEDeveloperExtensionEditDefaultScript

function revIDEDeveloperExtensionFetchDefaultScript pFolder
   return revIDEExtensionFetchDefaultScript(pFolder, sExtensionDetailsA[pFolder]["name"], false)
end revIDEDeveloperExtensionFetchDefaultScript
